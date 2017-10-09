#!/usr/bin/env bash

#https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
#set -euo pipefail
set -eo pipefail

if [ "${DEBUG}" = "true" ]; then
    set -x
fi

# Convert a http | https proxy into JVM properties as specified by https://docs.oracle.com/javase/8/docs/technotes/guides/net/proxies.html
# proxyVariableAsJvmProperty 'http://localhost:8080' will produce the following output:
#   http.proxyHost=localhost
#   http.proxyPort=8080
#
function proxyVariableAsJvmProperty() {
    local proxyURL=$1
    local pattern='(.+)://((.+):([[:digit:]]{1,5})|(.+^:))'

    if [ "${proxyURL}" = "" ]; then
      return 0
    fi

    if [[ ${proxyURL} =~ ^${pattern} ]]; then
      if [ ! "${BASH_REMATCH[4]}" = "" ]; then
        echo "${BASH_REMATCH[1]}.proxyHost=${BASH_REMATCH[3]}"
        echo "${BASH_REMATCH[1]}.proxyPort=${BASH_REMATCH[4]}"
      else
        echo "${BASH_REMATCH[1]}.proxyHost=${BASH_REMATCH[2]}"
      fi
    else
      return 1
    fi
}

# Convert a no_proxy style proxy exclusion list into JVM properties as specified by https://docs.oracle.com/javase/8/docs/technotes/guides/net/proxies.html
# noProxyVariableAsJvmProperty 'http' 'localhost,127.0.0.1,softwarecraftsmen.at' will produce the following output
#   http.nonProxyHosts=localhost|127.0.0.1|softwarecraftsmen.at
#
function noProxyVariableAsJvmProperty() {
  local scheme=$1
  local noProxy=$2
  echo "${scheme}.nonProxyHosts=${noProxy//,/|}"
}
