#!/usr/bin/env bash
set -euo pipefail

xml_escape() {
  local value="${1:-}"
  value="${value//&/&amp;}"
  value="${value//</&lt;}"
  value="${value//>/&gt;}"
  value="${value//\"/&quot;}"
  value="${value//\'/&apos;}"
  printf '%s' "$value"
}

env_to_property() {
  local name="$1"
  name="${name//___/-}"
  name="${name//__/_}"
  name="${name//_/.}"
  printf '%s' "$name"
}

has_prefixed_env() {
  local prefix="$1"
  env | grep -q "^${prefix}_"
}

render_xml() {
  local prefix="$1"
  local target="$2"

  if ! has_prefixed_env "$prefix"; then
    return 0
  fi

  {
    printf '<?xml version="1.0"?>\n'
    printf '<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>\n'
    printf '<configuration>\n'
    env | sort | while IFS='=' read -r key value; do
      if [[ "$key" == "${prefix}_"* ]]; then
        local raw_name="${key#${prefix}_}"
        local property_name
        property_name="$(env_to_property "$raw_name")"
        printf '  <property>\n'
        printf '    <name>%s</name>\n' "$(xml_escape "$property_name")"
        printf '    <value>%s</value>\n' "$(xml_escape "$value")"
        printf '  </property>\n'
      fi
    done
    printf '</configuration>\n'
  } > "$target"
}

cat > "${HADOOP_CONF_DIR}/hadoop-env.sh" <<EOF
export JAVA_HOME=${JAVA_HOME}
export HADOOP_HOME=${HADOOP_HOME}
export HADOOP_CONF_DIR=${HADOOP_CONF_DIR}
EOF

cat > "${SPARK_CONF_DIR}/spark-env.sh" <<EOF
export JAVA_HOME=${JAVA_HOME}
export HADOOP_CONF_DIR=${HADOOP_CONF_DIR}
export YARN_CONF_DIR=${YARN_CONF_DIR}
export SPARK_DIST_CLASSPATH="\$(${HADOOP_HOME}/bin/hadoop classpath)"
EOF

render_xml CORE_CONF "${HADOOP_CONF_DIR}/core-site.xml"
render_xml HDFS_CONF "${HADOOP_CONF_DIR}/hdfs-site.xml"
render_xml YARN_CONF "${HADOOP_CONF_DIR}/yarn-site.xml"
render_xml MAPRED_CONF "${HADOOP_CONF_DIR}/mapred-site.xml"