#!/bin/bash
set -eo pipefail
set -x

# Set umask of "u=,g=w,o=rwx" (0027) recommended for Bitbucket
umask 0027

source /http-proxy.sh

function configureSetupWizard() {

    pushd ${BITBUCKET_HOME}/shared

    if [ -z ${BITBUCKET_DISPLAYNAME+x} ]; then
      echo "BITBUCKET_DISPLAYNAME not set";
    else
      echo "setup.displayName=$BITBUCKET_DISPLAYNAME" >> bitbucket.properties;
    fi

    if [ -z ${BITBUCKET_BASEURL+x} ]; then
      echo "BITBUCKET_BASEURL not set";
    else
      echo "setup.baseUrl=$BITBUCKET_BASEURL" >> bitbucket.properties;
    fi

    if [ -z ${BITBUCKET_LICENSE+x} ]; then
      echo "BITBUCKET_LICENSE not set";
    else
      echo "setup.license=$BITBUCKET_LICENSE" >> bitbucket.properties;
    fi

    if [ -z ${BITBUCKET_SYSADMIN_USERNAME+x} ]; then
      echo "BITBUCKET_SYSADMIN_USERNAME not set";
    else
      echo "setup.sysadmin.username=${BITBUCKET_SYSADMIN_USERNAME:-bitbucket}" >> bitbucket.properties
    fi

    if [ -z ${BITBUCKET_SYSADMIN_PASSWORD+x} ]; then
      echo "BITBUCKET_SYSADMIN_PASSWORD not set";
    else
      echo "setup.sysadmin.password=${BITBUCKET_SYSADMIN_PASSWORD:-bitbucket}" >> bitbucket.properties
    fi

    if [ -z ${BITBUCKET_SYSADMIN_DISPLAYNAME+x} ]; then
      echo "BITBUCKET_SYSADMIN_DISPLAYNAME not set";
    else
      echo "setup.sysadmin.displayName=${BITBUCKET_SYSADMIN_DISPLAYNAME:-Bitbucket}" >> bitbucket.properties
    fi

    if [ -z ${BITBUCKET_SYSADMIN_EMAIL+x} ]; then
      echo "BITBUCKET_SYSADMIN_EMAIL not set";
    else
      echo "setup.sysadmin.emailAddress=${BITBUCKET_SYSADMIN_EMAIL:-bitbucket@server.com}" >> bitbucket.properties
    fi

    popd
}

function configureJDBC () {
    pushd ${BITBUCKET_HOME}/shared

    if [ -z ${BITBUCKET_JDBC_USER+x} ]; then
      echo "BITBUCKET_JDBC_USER not set";
    else
      echo "jdbc.user=${BITBUCKET_JDBC_USER:-bitbucket}" >> bitbucket.properties
    fi

    if [ -z ${BITBUCKET_JDBC_PASSWORD+x} ]; then
      echo "BITBUCKET_JDBC_PASSWORD not set";
    else
      echo "jdbc.password=${BITBUCKET_JDBC_PASSWORD:-bitbucket}" >> bitbucket.properties
    fi

    if [ -z ${BITBUCKET_JDBC_DRIVER+x} ]; then
      echo "BITBUCKET_JDBC_DRIVER not set";
    else
      echo "jdbc.driver=${BITBUCKET_JDBC_DRIVER}" >> bitbucket.properties
    fi

    if [ -z ${BITBUCKET_JDBC_URL+x} ]; then
      echo "BITBUCKET_JDBC_URL not set";
    else
      echo "jdbc.url=${BITBUCKET_JDBC_URL}" >> bitbucket.properties
    fi

    popd
}

function configureServer() {
    pushd ${BITBUCKET_HOME}/shared

    if [ -z ${SERVER_SECURE+x} ]; then
      echo "SERVER_SECURE not set";
    else
      echo "server.secure=${SERVER_SECURE:-false}" >> bitbucket.properties
    fi

    if [ -z ${SERVER_SCHEME+x} ]; then
      echo "SERVER_SCHEME not set";
    else
      echo "server.scheme=${SERVER_SCHEME:-http}" >> bitbucket.properties
    fi

    if [ -z ${SERVER_PROXY_PORT+x} ]; then
      echo "SERVER_PROXY_PORT not set";
    else
      echo "server.proxy-port=${SERVER_PROXY_PORT:-7990}" >> bitbucket.properties
    fi

    if [ -z ${SERVER_PROXY_NAME+x} ]; then
      echo "SERVER_PROXY_NAME not set";
    else
      echo "server.proxy-name=${SERVER_PROXY_NAME}" >> bitbucket.properties
    fi

    popd
}

function configureHttpProxy() {
    # in case JVM_SUPPORT_RECOMMENDED_ARGS is already set then we will not try to override or modify it.
    if [ -z ${JVM_SUPPORT_RECOMMENDED_ARGS} ]; then
        local systemPropertyArgument

        if [ -z ${http_proxy+x} ]; then
          echo "http_proxy not set";
        else
          systemPropertyArgument=$(proxyVariableAsJvmSystemProperty ${http_proxy})
        fi

        if [ -z ${https_proxy+x} ]; then
          echo "https_proxy not set";
        else
          systemPropertyArgument=${systemPropertyArgument}$(proxyVariableAsJvmSystemProperty ${https_proxy})
        fi

        if [ -z ${no_proxy+x} ]; then
          echo "no_proxy not set";
        else
          systemPropertyArgument=${systemPropertyArgument}$(noProxyVariableAsJvmSystemProperty 'http' ${no_proxy})
          systemPropertyArgument=${systemPropertyArgument}$(noProxyVariableAsJvmSystemProperty 'https' ${no_proxy})
        fi

        export JVM_SUPPORT_RECOMMENDED_ARGS=${systemPropertyArgument}
    fi
}

# Configure basic configuration parameters
# see https://confluence.atlassian.com/bitbucketserver/automated-setup-for-bitbucket-server-776640098.html

# The container configuration is only applied once!
if [ ! -f ${BITBUCKET_HOME}/shared/bitbucket.properties.configured ]; then
    configureSetupWizard
    configureJDBC
    configureServer
    configureHttpProxy
    touch ${BITBUCKET_HOME}/shared/bitbucket.properties.configured
fi

: ${ELASTICSEARCH_ENABLED:=true}
: ${APPLICATION_MODE:=}

ARGS="$@"

# Start Bitbucket without Elasticsearch
if [ "${ELASTICSEARCH_ENABLED}" == "false" ] || [ "${APPLICATION_MODE}" == "mirror" ]; then
    ARGS="--no-search ${ARGS}"
fi

export BITBUCKET_USER=${RUN_USER}
exec "${BITBUCKET_INSTALL_DIR}/bin/start-bitbucket.sh" ${ARGS}
