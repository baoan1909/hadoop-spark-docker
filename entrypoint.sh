#!/usr/bin/env bash
set -euo pipefail

wait_for() {
  local preconditions="${SERVICE_PRECONDITION:-}"
  local host port

  for endpoint in $preconditions; do
    host="${endpoint%:*}"
    port="${endpoint##*:}"

    if [[ -z "$host" || -z "$port" || "$host" == "$port" ]]; then
      continue
    fi

    printf 'Waiting for %s:%s' "$host" "$port"
    until nc -z "$host" "$port" >/dev/null 2>&1; do
      printf '.'
      sleep 2
    done
    printf ' ready\n'
  done
}

/usr/local/bin/configure-hadoop-spark
wait_for

role="${1:-}"
shift || true

if [[ -z "$role" && "${HADOOP_NODE:-}" == "namenode" ]]; then
  role="namenode"
elif [[ -z "$role" && "${HADOOP_NODE:-}" == "datanode" ]]; then
  role="datanode"
fi

case "$role" in
  namenode)
    if [[ ! -f /hadoop/dfs/name/current/VERSION ]]; then
      "${HADOOP_HOME}/bin/hdfs" namenode -format -force -nonInteractive "${CLUSTER_NAME:-hadoop-cluster}"
    fi
    exec "${HADOOP_HOME}/bin/hdfs" namenode "$@"
    ;;
  datanode)
    exec "${HADOOP_HOME}/bin/hdfs" datanode "$@"
    ;;
  resourcemanager)
    exec "${HADOOP_HOME}/bin/yarn" resourcemanager "$@"
    ;;
  nodemanager)
    exec "${HADOOP_HOME}/bin/yarn" nodemanager "$@"
    ;;
  spark-master)
    exec "${SPARK_HOME}/bin/spark-class" org.apache.spark.deploy.master.Master \
      --host "${SPARK_MASTER_HOST:-$(hostname)}" \
      --port "${SPARK_MASTER_PORT:-7077}" \
      --webui-port "${SPARK_MASTER_WEBUI_PORT:-8080}" \
      "$@"
    ;;
  spark-worker)
    exec "${SPARK_HOME}/bin/spark-class" org.apache.spark.deploy.worker.Worker \
      --port "${SPARK_WORKER_PORT:-7078}" \
      --webui-port "${SPARK_WORKER_WEBUI_PORT:-8081}" \
      "${SPARK_MASTER:-spark://baoan-master:7077}" \
      "$@"
    ;;
  bash|sh)
    exec "$role" "$@"
    ;;
  *)
    echo "Usage: $0 {namenode|datanode|resourcemanager|nodemanager|spark-master|spark-worker}"
    exit 1
    ;;
esac
