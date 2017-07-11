FROM buildpack-deps:jessie
MAINTAINER Software Craftsmen GmbH & Co KG <office@software-craftsmen.at>

#
# For setting up CATALINA_OPTS, credits go to https://bitbucket.org/atlassian/docker-atlassian-bitbucket-server
#
#
# For the startup and permission downgrade credits go to https://bitbucket.org/atlassian/docker-atlassian-bitbucket-server
# For the startup and permission downgrade credits go to https://bitbucket.org/atlassian/docker-atlassian-bitbucket-server
#

ARG "version=unknown"
ARG "build_date=unknown"
ARG "commit_hash=unknown"
ARG "vcs_url=unknown"
ARG "vcs_branch=unknown"
ARG "vcs_ref=unknown"

LABEL org.label-schema.vendor="Software Craftsmen Gmbh & Co KG" \
    org.label-schema.name="jenkins-backup" \
    org.label-schema.description="Jenkins Backup" \
    org.label-schema.usage="${vcs_url}" \
    org.label-schema.url="${vcs_url}" \
    org.label-schema.vcs-url=$vcs_url \
    org.label-schema.vcs-branch=$vcs_branch \
    org.label-schema.vcs-ref=$vcs_ref \
    org.label-schema.version=$version \
    org.label-schema.schema-version="1.0" \
    org.label-schema.build-date=$build_date

RUN if [ ! ${http_proxy} = "" ] ; then echo "Acquire::http::Proxy \"${http_proxy}\";" >> /etc/apt/apt.conf.d/98proxy; fi && \
    if [ ! ${https_proxy} = "" ] ; then echo "Acquire::https::Proxy \"${https_proxy}\";" >> /etc/apt/apt.conf.d/98proxy; fi && \
    if [ ! ${http_proxy} = "" ] ; then echo "http_proxy=${http_proxy}" >> /etc/wgetrc; fi && \
    if [ ! ${https_proxy} = "" ] ; then echo "https_proxy=${https_proxy}" >> /etc/wgetrc; fi

ENV BITBUCKET_VERSION=4.14.2
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

ARG VCS_REF
LABEL org.label-schema.vcs-ref=${VCS_REF} \
      org.label-schema.vcs-url=${VCS_URL}
