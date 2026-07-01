FROM ubuntu:24.04

ARG HADOOP_VERSION=3.4.3
ARG SPARK_VERSION=4.1.2
ARG JAVA_VERSION_ENCODED=21.0.11%2B9

ENV JAVA_HOME=/opt/java/openjdk \
    HADOOP_HOME=/opt/hadoop \
    HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop \
    YARN_CONF_DIR=/opt/hadoop/etc/hadoop \
    SPARK_HOME=/opt/spark \
    SPARK_CONF_DIR=/opt/spark/conf \
    HADOOP_USER_NAME=root \
    DEBIAN_FRONTEND=noninteractive

ENV PATH="${JAVA_HOME}/bin:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin:${SPARK_HOME}/bin:${SPARK_HOME}/sbin:${PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      bash \
      ca-certificates \
      curl \
      netcat-openbsd \
      procps \
      python3 \
      python3-pip \
      tini \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/java /opt/downloads \
    && curl -fsSL -o /opt/downloads/jdk.tar.gz \
      "https://api.adoptium.net/v3/binary/version/jdk-${JAVA_VERSION_ENCODED}/linux/x64/jdk/hotspot/normal/eclipse?project=jdk" \
    && tar -xzf /opt/downloads/jdk.tar.gz -C /opt/java \
    && mv /opt/java/* "${JAVA_HOME}" \
    && rm -f /opt/downloads/jdk.tar.gz

RUN curl -fsSL -o /opt/downloads/hadoop.tar.gz \
      "https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz" \
    || curl -fsSL -o /opt/downloads/hadoop.tar.gz \
      "https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz" \
    && tar -xzf /opt/downloads/hadoop.tar.gz -C /opt \
    && mv "/opt/hadoop-${HADOOP_VERSION}" "${HADOOP_HOME}" \
    && rm -f /opt/downloads/hadoop.tar.gz

RUN curl -fsSL -o /opt/downloads/spark.tar.gz \
      "https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz" \
    || curl -fsSL -o /opt/downloads/spark.tar.gz \
      "https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3-scala2.13.tgz" \
    || curl -fsSL -o /opt/downloads/spark.tar.gz \
      "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz" \
    || curl -fsSL -o /opt/downloads/spark.tar.gz \
      "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3-scala2.13.tgz" \
    && tar -xzf /opt/downloads/spark.tar.gz -C /opt \
    && mv /opt/spark-${SPARK_VERSION}-bin-* "${SPARK_HOME}" \
    && rm -rf /opt/downloads

COPY conf/hadoop/core-site.xml "${HADOOP_CONF_DIR}/"
COPY conf/hadoop/hadoop-env.sh "${HADOOP_CONF_DIR}/"
COPY conf/hadoop/hdfs-site.xml "${HADOOP_CONF_DIR}/"
COPY conf/hadoop/mapred-site.xml "${HADOOP_CONF_DIR}/"
COPY conf/hadoop/workers "${HADOOP_CONF_DIR}/"
COPY conf/hadoop/yarn-site.xml "${HADOOP_CONF_DIR}/"
COPY conf/spark/spark-defaults.conf "${SPARK_CONF_DIR}/"
COPY scripts/configure.sh /usr/local/bin/configure-hadoop-spark
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /usr/local/bin/configure-hadoop-spark /entrypoint.sh \
    && mkdir -p /hadoop/dfs/name /hadoop/dfs/data /tmp/hadoop-root /tmp/yarn-root/nm-local-dir /tmp/spark-events \
    && chmod -R 1777 /tmp/hadoop-root /tmp/yarn-root /tmp/spark-events

EXPOSE 7077 7078 8080 8081 8030 8031 8032 8033 8040 8041 8042 8088 9000 9864 9866 9867 9870

ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
