/// @title Standard Token Contract.

contract TokenInterface {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    /// Public variables of the token, all used for display 
    string public name;
    string public symbol;

    /// Total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice Send `_amount` tokens to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _amount) returns (bool success);

    /// @notice Send `_amount` tokens to `_to` from `_from` on the condition it
    /// is approved by `_from`
    /// @param _from The address of the origin of the transfer
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_amount` tokens on
    /// its behalf
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _amount) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens of _owner that _spender is allowed
    /// to spend
    function allowance(
        address _owner,
        address _spender
    ) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
    );
}


contract Token is TokenInterface {
    // Protects users by preventing the execution of method calls that
    // inadvertently also transferred ether
    modifier noEther() {if (msg.value > 0) throw; _}

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) noEther returns (bool success) {
        if (balances[msg.sender] >= _amount && _amount > 0) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
           return false;
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) noEther returns (bool success) {

        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0) {

            balances[_to] += _amount;
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}
/*
Basic account, used by the Crowdsale contract to manage the rewards. 
*/

contract ManagedAccountInterface {
    // The only address with permission to withdraw from this account
    address public owner;
    // If true, only the owner of the account can receive ether from it
    bool public payOwnerOnly;
    // The sum of ether (in wei) which has been sent to this contract
    uint public accumulatedInput;

    /// @notice Sends `_amount` of wei to _recipient
    /// @param _amount The amount of wei to send to `_recipient`
    /// @param _recipient The address to receive `_amount` of wei
    /// @return True if the send completed
    function payOut(address _recipient, uint _amount) returns (bool);

    event PayOut(address indexed _recipient, uint _amount);
}


contract ManagedAccount is ManagedAccountInterface{

    // The constructor sets the owner of the account
    function ManagedAccount(address _owner, bool _payOwnerOnly) {
        owner = _owner;
        payOwnerOnly = _payOwnerOnly;
    }

    // When the contract receives a transaction without data this is called. 
    // It counts the amount of ether it receives and stores it in 
    // accumulatedInput.
    function() {
        accumulatedInput += msg.value;
    }

    function payOut(address _recipient, uint _amount) returns (bool) {
        if (msg.sender != owner || msg.value > 0 || (payOwnerOnly && _recipient != owner))
            throw;
        if (_recipient.call.value(_amount)()) {
            PayOut(_recipient, _amount);
            return true;
        } else {
            return false;
        }
    }
}
/*
 * Token Creation contract, used by the Crowdsale contract to create its tokens and initialize
 * its ether.
*/

//import "./Token.sol";
//import "./ManagedAccount.sol";

contract TokenCreationInterface {

    // End of token creation, in Unix time
    uint public closingTime;
    // Minimum fueling goal of the token creation, denominated in tokens to
    // be created
    uint public minTokensToCreate;
    // True if the Crowdsale reached its minimum fueling goal, false otherwise
    bool public isFueled;
    // tracks the amount of wei given from each contributor (used for refund)
    mapping (address => uint256) weiGiven;

    /// @dev Constructor setting the minimum fueling goal and the
    /// end of the Token Creation
    /// @param _minTokensToCreate Minimum fueling goal in number of
    ///        Tokens to be created
    /// @param _closingTime Date (in Unix time) of the end of the Token Creation
    // This is the constructor: it can not be overloaded so it is commented out
    //  function TokenCreation(
        //  uint _minTokensTocreate,
        //  uint _closingTime,
        //  string _tokenName,
        //  string _tokenSymbol
    //  );

    /// @notice Create Token with `_tokenHolder` as the initial owner of the Token
    /// @param _tokenHolder The address of the Tokens's recipient
    /// @return Whether the token creation was successful
    function createTokenProxy(address _tokenHolder) internal returns (bool success);

    /// @notice Refund `msg.sender` in the case the Token Creation did
    /// not reach its minimum fueling goal
    function refund();

    event FuelingToDate(uint value);
    event CreatedToken(address indexed to, uint amount);
    event Refund(address indexed to, uint value);
}


contract TokenCreation is TokenCreationInterface, Token {
    function TokenCreation(
        uint _minTokensToCreate,
        uint _closingTime,
        string _tokenName,
        string _tokenSymbol) {

        closingTime = _closingTime;
        minTokensToCreate = _minTokensToCreate;
        name = _tokenName;
        symbol = _tokenSymbol;
    }

    function createTokenProxy(address _tokenHolder) internal returns (bool success) {
        if (now < closingTime && msg.value > 0) {
            uint token = msg.value / 1000000000000000000;    //one ether one token
            balances[_tokenHolder] += token;
            totalSupply += token;
            weiGiven[_tokenHolder] += msg.value;
            CreatedToken(_tokenHolder, token);
            if (totalSupply >= minTokensToCreate && !isFueled) {
                isFueled = true;
                FuelingToDate(totalSupply);
            }
            return true;
        }
        throw;
    }

    function refund() noEther {
        if (now > closingTime && !isFueled) {
            // Execute refund
            if (msg.sender.send(weiGiven[msg.sender])) { 
            // its the recipients responsibilty to ensure 
            // their address does not use too much gas
                Refund(msg.sender, weiGiven[msg.sender]);
                totalSupply -= balances[msg.sender];
                balances[msg.sender] = 0;
                weiGiven[msg.sender] = 0;
            }
        }
    }
}	
/*
Standard smart contract for Crowdsale
*/
contract CrowdsaleInterface {

    // The amount of days for which people who try to participate in the
    // creation by calling the fallback function will still get their ether back
    uint constant creationGracePeriod = 2 minutes;
    // The minimum debate period that a generic proposal can have
    uint constant minProposalDebatePeriod = 3 minutes;
    // Period after which a proposal is closed
    uint constant executeProposalPeriod = 3 minutes;

    // Proposals to spend the Crowdsale contract's ether to the sponsor's account  
    Proposal[] public proposals;
    // The quorum needed for each proposal is partially calculated by
    // totalSupply / minQuorumDivisor
    uint public minQuorumDivisor;

    // Address of the curator
    address public curator;
    // The whitelist: List of addresses the Crowdsale contract is allowed to send ether to
    mapping (address => bool) public allowedRecipients;

    // Tracks the addresses that own Reward Tokens. Reward Tokens represent the proportion 
	// of the rewards that the investor has the right to receive
    // These Reward Tokens are generated when the Crowdsale contract spends ether
    mapping (address => uint) public rewardToken;
    // Total supply of rewardToken
    uint public totalRewardToken;

    // The account used to manage the rewards which are to be distributed to the investors
    ManagedAccount public rewardAccount;
    // Amount of rewards (in wei) already paid out to a certain address
    mapping (address => uint) public paidOut;
    // Map of addresses blocked during a vote (not allowed to transfer 
    // tokens). The address points to the proposal ID.
    mapping (address => uint) public blocked;

    struct Proposal {
        // The address where the `amount` will go to.
        address recipient;
        // The amount to transfer to `recipient` if the proposal is accepted.
        uint amount;
        // A plain text description of the proposal
        string description;
        // A unix timestamp, denoting the end of the voting period
        uint votingDeadline;
        // True if the proposal's votes have yet to be counted, otherwise False
        bool open;
        // True if quorum has been reached, the votes have been counted, and
        // the majority said yes
        bool proposalPassed;
        // A hash to check validity of a proposal
        bytes32 proposalHash;
        // Number of Tokens in favor of the proposal
        uint yea;
        // Number of Tokens opposed to the proposal
        uint nay;
        // Simple mapping to check if a shareholder has voted for it
        mapping (address => bool) votedYes;
        // Simple mapping to check if a shareholder has voted against it
        mapping (address => bool) votedNo;
        // Address of the shareholder who created the proposal
        address creator;
    }

    // Used to restrict access to certain functions to only Token Holders
    modifier onlyTokenholders {}

    /// @dev Constructor setting the Curator
    ///      as well as the parameters for Token Creation
    /// @param _curator The Curator
    /// @param _minTokensToCreate Minimum required wei-equivalent tokens to be created
    /// @param _closingTime Date (in Unix time) of the end of Token Creation
    /// @param _tokenName The name that the token will have
    /// @param _tokenSymbol The ticker symbol that the token should have
    // This is the constructor: it can not be overloaded so it is commented out
    //  function Crowdsale(
        //  address _curator,
        //  uint _minTokensToCreate,
        //  uint _closingTime,
        //  string _tokenName,
        //  string _tokenSymbol
    //  );

    /// @notice Create Token with `msg.sender` as the beneficiary
    /// @return Whether the token creation was successful
    function () returns (bool success);

    /// @notice `msg.sender` creates a proposal to send `_amount` Wei to
    /// `_recipient` 
    /// @param _recipient Address of the recipient of the proposed transaction
    /// @param _amount Amount of wei to be sent with the proposed transaction
    /// @param _description String describing the proposal
    /// @param _debatingSeconds Time used for debating a proposal
    /// @return The proposal ID. Needed for voting on the proposal
    function newProposal(
        address _recipient,
        uint _amount,
        string _description,
        uint _debatingSeconds
    ) returns (uint _proposalID);

    /// @notice Vote on proposal `_proposalID` with `_supportsProposal`
    /// @param _proposalID The proposal ID
    /// @param _supportsProposal Yes/No - support of the proposal
    function vote(uint _proposalID, bool _supportsProposal);

    /// @notice Checks whether proposal `_proposalID` has been voted for or rejected, and executes the
    /// transaction in the case it has been voted for
    /// @param _proposalID The proposal ID
    /// @return Whether the proposed transaction has been executed or not
    function executeProposal(
        uint _proposalID
    ) returns (bool _success);


    /// @notice Add a new possible recipient `_recipient` to the whitelist so
    /// that the Crowdsale contract can send transactions to them (using proposals)
    /// @param _recipient New recipient address
    /// @dev Can only be called by the current Curator
    /// @return Whether successful or not
    function changeAllowedRecipients(address _recipient, bool _allowed) external returns (bool _success);

    /// @notice Get my portion of the reward that was sent to `rewardAccount`
    /// @return Whether the call was successful
    function getMyReward() returns(bool _success);

    /// @notice Withdraw `_account`'s portion of the reward from `rewardAccount`
    /// to `_account`'s balance
    /// @return Whether the call was successful
    function withdrawRewardFor(address _account) internal returns (bool _success);

    /// @notice Send `_amount` tokens to `_to` from `msg.sender`. Prior to this
    /// getMyReward() is called.
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transfered
    /// @return Whether the transfer was successful or not
    function transferWithoutReward(address _to, uint256 _amount) returns (bool success);

    /// @notice Send `_amount` tokens to `_to` from `_from` on the condition it
    /// is approved by `_from`. Prior to this getMyReward() is called.
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transfered
    /// @return Whether the transfer was successful or not
    function transferFromWithoutReward(
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool success);

    /// @return total number of proposals ever created
    function numberOfProposals() constant returns (uint _numberOfProposals);

    /// @param _account The address of the account which is checked.
    /// @return Whether the account is blocked (not allowed to transfer tokens) or not.
    function isBlocked(address _account) internal returns (bool);

    event ProposalAdded(
        uint indexed proposalID,
        address recipient,
        uint amount,
        string description
    );
    event Voted(uint indexed proposalID, bool position, address indexed voter);
    event ProposalTallied(uint indexed proposalID, bool result, uint quorum);
    event AllowedRecipientChanged(address indexed _recipient, bool _allowed);
}

// The Crowdsale contract itself
contract Crowdsale is CrowdsaleInterface, Token, TokenCreation {

    // Modifier that allows only shareholders to vote and create new proposals
    modifier onlyTokenholders {
        if (balanceOf(msg.sender) == 0) throw;
            _
    }

    function Crowdsale(
        address _curator,
        uint _minTokensToCreate,
        uint _closingTime,
        string _tokenName, 
        string _tokenSymbol
    ) TokenCreation(
        _minTokensToCreate, 
        _closingTime, 
        _tokenName, 
        _tokenSymbol) noEther {
	
        curator = _curator;
        rewardAccount = new ManagedAccount(address(this), false);
        if (address(rewardAccount) == 0)
            throw;
        minQuorumDivisor = 3; // sets the minimal quorum to 50%
        proposals.length = 1; // avoids a proposal with ID 0 because it is used

        allowedRecipients[address(this)] = true;
        allowedRecipients[curator] = true;
    }

    function () returns (bool success) {
        if (now < closingTime + creationGracePeriod)
            return createTokenProxy(msg.sender);
        else
            return true;
    }


    function newProposal(
        address _recipient,
        uint _amount,
        string _description,
        uint _debatingSeconds
    ) noEther returns (uint _proposalID) {

        // Sanity check
        if (!isRecipientAllowed(_recipient) 
			||(_debatingSeconds <  minProposalDebatePeriod)
		    || msg.sender != _recipient) {    //only the recipient can create new proposal   
            throw;
        }

        if (_debatingSeconds > 8 weeks)
            throw;

        if (!isFueled
            || now < closingTime) {
            throw;
        }

        if (now + _debatingSeconds < now) // prevents overflow
            throw;


        _proposalID = proposals.length++;
        Proposal p = proposals[_proposalID];
        p.recipient = _recipient;
        p.amount = _amount;
        p.description = _description;
        p.proposalHash = sha3(_recipient, _amount);
        p.votingDeadline = now + _debatingSeconds;
        p.open = true;
        //p.proposalPassed = False; // that's default
        p.creator = msg.sender;


        ProposalAdded(
            _proposalID,
            _recipient,
            _amount,
            _description
        );
    }


    function vote(uint _proposalID, bool _supportsProposal) onlyTokenholders noEther {

        Proposal p = proposals[_proposalID];
        if (p.votedYes[msg.sender]
            || p.votedNo[msg.sender]
            || now >= p.votingDeadline) {

            throw;
        }

        if (_supportsProposal) {
            p.yea += balances[msg.sender];
            p.votedYes[msg.sender] = true;
        } else {
            p.nay += balances[msg.sender];
            p.votedNo[msg.sender] = true;
        }

        if (blocked[msg.sender] == 0) {
            blocked[msg.sender] = _proposalID;
        } else if (p.votingDeadline > proposals[blocked[msg.sender]].votingDeadline) {
            // this proposal's voting deadline is further into the future than
            // the proposal that blocks the sender so make it the blocker
            blocked[msg.sender] = _proposalID;
        }

        Voted(_proposalID, _supportsProposal, msg.sender);
    }


    function executeProposal(
        uint _proposalID
    ) noEther returns (bool _success) {

        Proposal p = proposals[_proposalID];

        uint waitPeriod = executeProposalPeriod;
        // If we are over deadline and waiting period, assert proposal is closed
        if (p.open && now > p.votingDeadline + waitPeriod) {
            closeProposal(_proposalID);
            return;
        }

        // Check if the proposal can be executed
        if (now < p.votingDeadline  // has the voting deadline arrived?
            // Have the votes been counted?
            || !p.open
            || p.proposalPassed // anyone trying to call us recursively?
            // Does the transaction code match the proposal?
            || p.proposalHash != sha3(p.recipient, p.amount)) {

            throw;
        }

        // If the curator removed the recipient from the whitelist, close the proposal
        // in order to allow unblocking of voters
        if (!isRecipientAllowed(p.recipient)) {
            closeProposal(_proposalID);
            return;
        }

        bool proposalCheck = true;

        if (p.amount > this.balance)
            proposalCheck = false;

        uint quorum = p.yea + p.nay;

        // Execute result
        if (quorum >= minQuorum(p.amount) && p.yea > p.nay && proposalCheck) {
            // we are setting this here before the CALL() value transfer to
            // assure that in the case of a malicious recipient contract trying
            // to call executeProposal() recursively money can't be transferred
            // multiple times out of the Crowsale contract
            p.proposalPassed = true;

            if (!p.recipient.call.value(p.amount)())
                throw;

            _success = true;

            // only create reward tokens when ether is not sent to the Crowdsale contract itself and
            // related addresses. Proxy addresses should be forbidden by the curator.
            if (p.recipient != address(this) && p.recipient != address(rewardAccount)
                && p.recipient != address(curator)) {

                rewardToken[address(this)] += p.amount;
                totalRewardToken += p.amount;
            }
        }

        closeProposal(_proposalID);

        // Initiate event
        ProposalTallied(_proposalID, _success, quorum);
    }


    function closeProposal(uint _proposalID) internal {
        Proposal p = proposals[_proposalID];
        p.open = false;
    }


    function getMyReward() noEther returns (bool _success) {
        return withdrawRewardFor(msg.sender);
    }


    function withdrawRewardFor(address _account) noEther internal returns (bool _success) {
        if ((balanceOf(_account) * rewardAccount.accumulatedInput()) / totalSupply < paidOut[_account])
            throw;

        uint reward =
            (balanceOf(_account) * rewardAccount.accumulatedInput()) / totalSupply - paidOut[_account];

        reward = rewardAccount.balance < reward ? rewardAccount.balance : reward;

        paidOut[_account] += reward;
        if (!rewardAccount.payOut(_account, reward))
            throw;

        return true;
    }


    function transfer(address _to, uint256 _value) returns (bool success) {
        if (isFueled
            && now > closingTime
            && !isBlocked(msg.sender)
            && !isBlocked(_to)
            && _to != address(this)
            && transferPaidOut(msg.sender, _to, _value)
            && super.transfer(_to, _value)) {

            return true;
        } else {
            throw;
        }
    }


    function transferWithoutReward(address _to, uint256 _value) returns (bool success) {
        if (!getMyReward())
            throw;
        return transfer(_to, _value);
    }


    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (isFueled
            && now > closingTime
            && !isBlocked(_from)
            && !isBlocked(_to)
            && _to != address(this)
            && transferPaidOut(_from, _to, _value)
            && super.transferFrom(_from, _to, _value)) {

            return true;
        } else {
            throw;
        }
    }


    function transferFromWithoutReward(
        address _from,
        address _to,
        uint256 _value
    ) returns (bool success) {

        if (!withdrawRewardFor(_from))
            throw;
        return transferFrom(_from, _to, _value);
    }


    function transferPaidOut(
        address _from,
        address _to,
        uint256 _value
    ) internal returns (bool success) {

        uint transferPaidOut = paidOut[_from] * _value / balanceOf(_from);
        if (transferPaidOut > paidOut[_from])
            throw;
        paidOut[_from] -= transferPaidOut;
        paidOut[_to] += transferPaidOut;
        return true;
    }

    function changeAllowedRecipients(address _recipient, bool _allowed) noEther external returns (bool _success) {
        if (msg.sender != curator)
            throw;
        allowedRecipients[_recipient] = _allowed;
        AllowedRecipientChanged(_recipient, _allowed);
        return true;
    }


    function isRecipientAllowed(address _recipient) internal returns (bool _isAllowed) {
        if (allowedRecipients[_recipient])
            return true;
        else
            return false;
    }


    function minQuorum(uint _value) internal constant returns (uint _minQuorum) {
        // minimum of 33.33% and maximum of 83.33%
        return totalSupply / minQuorumDivisor +
            (_value * totalSupply) / (2 * (this.balance + rewardToken[address(this)]));
    }


    function numberOfProposals() constant returns (uint _numberOfProposals) {
        // Don't count index 0. It's used by isBlocked() and exists from start
        return proposals.length - 1;
    }

    function isBlocked(address _account) internal returns (bool) {
        if (blocked[_account] == 0)
            return false;
        Proposal p = proposals[blocked[_account]];
        if (now > p.votingDeadline) {
            blocked[_account] = 0;
            return false;
        } else {
            return true;
        }
    }
}
