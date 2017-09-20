#!/bin/bash
set -euo pipefail
set -x

# Set umask of "u=,g=w,o=rwx" (0027) recommended for Bitbucket
umask 0027

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

# Configure basic configuration parameters
# see https://confluence.atlassian.com/bitbucketserver/automated-setup-for-bitbucket-server-776640098.html

# The setup wizard is only configured once!
if [ -f ${BITBUCKET_HOME}/bitbucket.properties.template ]; then
  if [ ! -f ${BITBUCKET_HOME}/shared/bitbucket.properties ]; then
    mkdir -p ${BITBUCKET_HOME}/shared
    mv ${BITBUCKET_HOME}/bitbucket.properties.template bitbucket.properties

    configureSetupWizard
  fi
fi

configureJDBC

: ${ELASTICSEARCH_ENABLED:=true}
: ${APPLICATION_MODE:=}

ARGS="$@"

# Start Bitbucket without Elasticsearch
if [ "${ELASTICSEARCH_ENABLED}" == "false" ] || [ "${APPLICATION_MODE}" == "mirror" ]; then
    ARGS="--no-search ${ARGS}"
fi

export BITBUCKET_USER=${RUN_USER}
exec "${BITBUCKET_INSTALL_DIR}/bin/start-bitbucket.sh" ${ARGS}
