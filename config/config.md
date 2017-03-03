## Kafka->Flink->Elasticsearch->集群搭建总结

## 附：项目参考地址:https://github.com/keiraqz/KafkaFlinkElastic

## 系统环境
ubuntu	v16.04
node	v7.2.1
java	v1.8.0
maven	v3.0.4


## elasticsearch,kafka下载tar二进制安装(tar zxf xx.tar.gz)
elasticsearch-5.2.1.tar.gz
kafka_2.10-0.10.2.0.tgz


## flink安装
git clone https://github.com/apache/flink.git
cd flink
mvn clean package -DskipTests


## 启动集群(打开多个控制台)

# start flink local
cd flink
./build-target/bin/start-local.sh

# start Kafka server and producer & consumer client 
cd kafka_2.10-0.10.2.0
./bin/zookeeper-server-start.sh config/zookeeper.properties
./bin/kafka-server-start.sh config/server.properties
./bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic viper_test
./bin/kafka-console-producer.sh --broker-list localhost:9092 --topic viper_test
./bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic viper_test --from-beginning

# start elasticsearch
cd elasticsearch-5.2.1
./bin/elasticsearch

# Create Elasticsearch index & doctype
curl -XPUT 'http://localhost:9200/viper-test/' -d '{
    "settings" : {
        "index" : {
            "number_of_shards" : 1,
            "number_of_replicas" : 0
        }
    }
}'

curl -XPUT 'localhost:9200/viper-test/_mapping/viper-log' -d '{
      "properties": {
            "ip": {
              "type": "string",
              "index": "not_analyzed"
            },
            "info": {
                "type": "string"
            }
      }
}'


## 项目构建

# 创建flink工程(用阿里云maven源或使用代理加速)
# packaging 名为jar
mvn archetype:generate -DarchetypeGroupId=org.apache.flink -DarchetypeArtifactId=flink-quickstart-java -DarchetypeVersion=1.2.0 -DinteractiveMode=true

# 替换pom.xml,并将./src/main/java/jar下所有文件替换为KafkaFlinkElastic.java
# 项目根目录下，build
mvn clean package -Pbuild-jar
../flink/build-target/bin/flink run ./target/[YOUR_PROJECT.jar]

# 查看结果
curl 'localhost:9200/viper-test/viper-log/_search?pretty'
