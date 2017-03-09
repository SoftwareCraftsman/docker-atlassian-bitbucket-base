FROM buildpack-deps:jessie
MAINTAINER Software Craftsmen GmbH & Co KG <office@software-craftsmen.at>

#
# For setting up CATALINA_OPTS, credits go to https://bitbucket.org/atlassian/docker-atlassian-bitbucket-server
#
#
# For the startup and permission downgrade credits go to https://bitbucket.org/atlassian/docker-atlassian-bitbucket-server
#

ARG VCS_REF
LABEL org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/SoftwareCraftsman/docker-atlassian-bitbucket-base.git"

ENV BITBUCKET_VERSION=4.14.1
ENV BITBUCKET_HOME=/var/atlassian/application-data/bitbucket
ENV BITBUCKET_INSTALL_DIR=/opt/atlassian/bitbucket

# Use the default unprivileged account. This could be considered bad practice
# on systems where multiple processes end up being executed by 'daemon' but
# here we only ever run one process anyway.
ENV RUN_USER            daemon
ENV RUN_GROUP           daemon

RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends git libtcnative-1 ssh \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

RUN wget --no-verbose https://www.atlassian.com/software/stash/downloads/binary/atlassian-bitbucket-${BITBUCKET_VERSION}-x64.bin -O atlassian-bitbucket-${BITBUCKET_VERSION}-x64.bin && \
    chmod a+x atlassian-bitbucket-${BITBUCKET_VERSION}-x64.bin

# Run the installer
# The response file is produced by an attended installation at /opt/atlassian/bitbucket/.install4j/response.varfile
COPY response.varfile response.varfile
# Run unattended installation with input from response.varfile
RUN ./atlassian-bitbucket-${BITBUCKET_VERSION}-x64.bin -q -varfile response.varfile && \
    rm atlassian-bitbucket-${BITBUCKET_VERSION}-x64.bin

COPY bitbucket.properties.template ${BITBUCKET_HOME}/bitbucket.properties.template

COPY catalina-connector-opts.sh ${BITBUCKET_INSTALL_DIR}/bin/
RUN mkdir -p ${BITBUCKET_INSTALL_DIR}/conf/Catalina && \
    chmod -R 700 ${BITBUCKET_INSTALL_DIR}/conf/Catalina && \
    chmod -R 700 ${BITBUCKET_INSTALL_DIR}/logs && \
    chmod -R 700 ${BITBUCKET_INSTALL_DIR}/temp && \
    chmod -R 700  ${BITBUCKET_INSTALL_DIR}/work && \
    chown -R ${RUN_USER}:${RUN_GROUP} ${BITBUCKET_INSTALL_DIR}/ && \
    ln --symbolic "/usr/lib/x86_64-linux-gnu/libtcnative-1.so" "${BITBUCKET_INSTALL_DIR}/lib/native/libtcnative-1.so" && \
    sed -i -e 's@^export CATALINA_OPTS$@. $PRGDIR/catalina-connector-opts.sh\nexport CATALINA_OPTS@' ${BITBUCKET_INSTALL_DIR}/bin/setenv.sh && \
    sed -i -e 's@$PRGDIR/catalina.sh@CATALINA_OPTS="$CATALINA_OPTS" $PRGDIR/catalina.sh@' -e 's@$PRGDIR/startup.sh@CATALINA_OPTS="$CATALINA_OPTS" $PRGDIR/startup.sh@' ${BITBUCKET_INSTALL_DIR}/bin/start-webapp.sh && \
    sed -i -e 's/port="7990"/port="7990" secure="${catalinaConnectorSecure}" scheme="${catalinaConnectorScheme}" proxyName="${catalinaConnectorProxyName}" proxyPort="${catalinaConnectorProxyPort}"/' ${BITBUCKET_HOME}/shared/server.xml

# HTTP port
EXPOSE 7990
# Control port
EXPOSE 8006
# SSH Port
EXPOSE 7999

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod a+x /docker-entrypoint.sh

WORKDIR $BITBUCKET_INSTALL_DIR

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["-fg"]