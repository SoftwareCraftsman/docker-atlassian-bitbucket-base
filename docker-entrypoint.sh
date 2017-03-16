#!/bin/bash
set -x

# Configure basic configuration parameters
# see https://confluence.atlassian.com/bitbucketserver/automated-setup-for-bitbucket-server-776640098.html

if [ -f ${BITBUCKET_HOME}/bitbucket.properties.template ]; then
  if [ ! -f ${BITBUCKET_HOME}/shared/bitbucket.properties ]; then
    mkdir -p ${BITBUCKET_HOME}/shared
    pushd ${BITBUCKET_HOME}/shared

    mv ${BITBUCKET_HOME}/bitbucket.properties.template bitbucket.properties

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

    if [ -z ${BITBUCKET_USER+x} ]; then
      echo "BITBUCKET_USER not set";
    else
      echo "setup.sysadmin.username=${BITBUCKET_USER:-bitbucket}" >> bitbucket.properties
    fi

    if [ -z ${BITBUCKET_PASSWORD+x} ]; then
      echo "BITBUCKET_PASSWORD not set";
    else
      echo "setup.sysadmin.password=${BITBUCKET_PASSWORD:-bitbucket}" >> bitbucket.properties
    fi

    if [ -z ${BITBUCKET_USER_DISPLAYNAME+x} ]; then
      echo "BITBUCKET_USER_DISPLAYNAME not set";
    else
      echo "setup.sysadmin.displayName=${BITBUCKET_USER_DISPLAYNAME:-Bitbucket}" >> bitbucket.properties
    fi

    if [ -z ${BITBUCKET_EMAIL+x} ]; then
      echo "BITBUCKET_EMAIL not set";
    else
      echo "setup.sysadmin.emailAddress=${BITBUCKET_EMAIL:-bitbucket@server.com}" >> bitbucket.properties
    fi

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
  fi
fi

#
# For the startup and permission downgrade credits go to https://bitbucket.org/atlassian/docker-atlassian-bitbucket-server
#

#exec $BITBUCKET_INSTALL_DIR/bin/start-bitbucket.sh "$@"

if [ "$UID" -eq 0 ]; then
    echo "User is currently root. Will change directories to daemon control, then downgrade permission to daemon"
    mkdir -p ${BITBUCKET_HOME}/lib
    chmod -R 700 "${BITBUCKET_HOME}"
    chown -R ${RUN_USER}:${RUN_GROUP} "${BITBUCKET_HOME}"
    # Now drop privileges
    exec su -s /bin/bash ${RUN_USER} -c "$BITBUCKET_INSTALL_DIR/bin/start-bitbucket.sh $@"
else
    exec $BITBUCKET_INSTALL_DIR/bin/start-bitbucket.sh "$@"
fi
