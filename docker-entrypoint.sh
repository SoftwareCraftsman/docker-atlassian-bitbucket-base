#!/bin/bash

# Configure basic configuration parameters
# see https://confluence.atlassian.com/bitbucketserver/automated-setup-for-bitbucket-server-776640098.html
# TODO print a warning when any of the credentials have assumed default values

if [ -f bitbucket.properties ]; then
  if [ ! -f $BITBUCKET_HOME/shared/bitbucket.properties ]; then
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

    mv bitbucket.properties $BITBUCKET_HOME/shared/
  fi
fi

# Start bitbucket in foreground mode
exec $BITBUCKET_INSTALL_DIR/$BITBUCKET_VERSION/bin/start-bitbucket.sh -fg
