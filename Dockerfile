FROM openjdk:8-jre-slim

RUN echo \
'deb http://mirrors.aliyun.com/debian/ buster main non-free contrib\n\
deb http://mirrors.aliyun.com/debian-security buster/updates main\n\
deb http://mirrors.aliyun.com/debian/ buster-updates main non-free contrib\n\
deb http://mirrors.aliyun.com/debian/ buster-backports main non-free contrib' \
    > /etc/apt/sources.list;

# Install required packages
RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        dirmngr \
        gosu \
        gnupg \
        python \
        procps \
        wget; \
    rm -rf /var/lib/apt/lists/*; \
    # Verify that gosu binary works
    gosu nobody true

ARG VERSION=1.1.2
ENV BASE_DIR=/usr/local
ENV HBASE_HOME=$BASE_DIR/hbase-$VERSION
ENV HBASE_CONF_DIR=$HBASE_HOME/conf \
    HBASE_LOGS_DIR=$HBASE_HOME/logs \
    HBASE_ZOOKEEPER_DIR=$HBASE_HOME/dataDir

ARG GPG_KEY=1C3489BD
ARG DISTRO_NAME=hbase-$VERSION-bin

# Download Apache HBASE, verify its PGP signature, untar and clean up
RUN set -eux; \
    ddist() { \
        local f="$1"; shift; \
        local distFile="$1"; shift; \
        local success=; \
        local distUrl=; \
        for distUrl in \
            # using hosts httpd to download hbase first
            http://192.168.4.59:80/ \
            https://archive.apache.org/dist/ \
            'https://www.apache.org/dyn/closer.cgi?action=download&filename=' \
            https://www-us.apache.org/dist/ \
            https://www.apache.org/dist/ \
        ; do \
            if wget -q -O "$f" "$distUrl$distFile" && [ -s "$f" ]; then \
                success=1; \
                break; \
            fi; \
        done; \
        [ -n "$success" ]; \
    }; \
    ddist "$DISTRO_NAME.tar.gz" "hbase/$VERSION/$DISTRO_NAME.tar.gz"; \
    ddist "$DISTRO_NAME.tar.gz.asc" "hbase/$VERSION/$DISTRO_NAME.tar.gz.asc"; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-key "$GPG_KEY" || \
    gpg --keyserver pgp.mit.edu --recv-keys "$GPG_KEY" || \
    gpg --keyserver keyserver.pgp.com --recv-keys "$GPG_KEY"; \
    gpg --batch --verify "$DISTRO_NAME.tar.gz.asc" "$DISTRO_NAME.tar.gz"; \
    tar -xzf "$DISTRO_NAME.tar.gz" -C "$BASE_DIR" && rm -rf "$HBASE_HOME/docs"; \
    rm -rf "$GNUPGHOME" "$DISTRO_NAME.tar.gz" "$DISTRO_NAME.tar.gz.asc";

ENTRYPOINT ["entrypoint.sh"]

WORKDIR $HBASE_HOME
ENV PATH $PATH:$HBASE_HOME/bin

