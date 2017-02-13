FROM buildpack-deps:jessie
MAINTAINER Software Craftsmen GmbH & Co KG <office@software-craftsmen.at>

ARG VCS_REF
LABEL org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/SoftwareCraftsman/docker-atlassian-bitbucket-base.git"

ENV BITBUCKET_VERSION=4.9.1
ENV BITBUCKET_HOME=/var/atlassian/application-data/bitbucket
ENV BITBUCKET_INSTALL_DIR=/opt/atlassian/bitbucket

#https://www.atlassian.com/software/stash/downloads/binary/atlassian-bitbucket-4.2.3-x64.bin

RUN wget --no-verbose https://www.atlassian.com/software/stash/downloads/binary/atlassian-bitbucket-$BITBUCKET_VERSION-x64.bin -O atlassian-bitbucket-$BITBUCKET_VERSION-x64.bin && \
    chmod a+x atlassian-bitbucket-$BITBUCKET_VERSION-x64.bin

ADD docker-entrypoint.sh docker-entrypoint.sh
RUN chmod a+x docker-entrypoint.sh

# Run the installer
# The response file is produced by an attended installation at /opt/atlassian/bitbucket/.install4j/response.varfile
ADD response.varfile response.varfile
# Run unattended installation with input from response.varfile
RUN ./atlassian-bitbucket-$BITBUCKET_VERSION-x64.bin -q -varfile response.varfile && \
    rm atlassian-bitbucket-$BITBUCKET_VERSION-x64.bin

# HTTP port
EXPOSE 7990
# Control port
EXPOSE 8006
# SSH Port
EXPOSE 7999

# Adjust this path if the installation location has been modified by the response.varfile
CMD ["./docker-entrypoint.sh"]
