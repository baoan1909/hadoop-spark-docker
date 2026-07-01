# Hadoop Spark Docker Image

Image dung cho bai cai dat Hadoop/Spark nhieu node.

## Software

- Ubuntu 24.04 LTS
- Java 21.0.11
- Hadoop 3.4.3
- Spark 4.1.2

## Build

```bash
docker build -t baoan/hadoop-spark:ubuntu24.04-java21.0.11-hadoop3.4.3-spark4.1.2 .
```

## Push

```bash
docker push baoan/hadoop-spark:ubuntu24.04-java21.0.11-hadoop3.4.3-spark4.1.2
```

## Run with Docker Compose

Sau khi push image, cac may chi can pull image va chay file compose tu du an `bigdata-docker-compose`:

```bash
docker pull baoan/hadoop-spark:ubuntu24.04-java21.0.11-hadoop3.4.3-spark4.1.2
docker compose -f docker-compose-master.yml up -d
```

Worker dung `docker-compose-worker01.yml` hoac `docker-compose-worker02.yml`.
