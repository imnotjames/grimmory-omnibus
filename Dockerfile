ARG ARCH=x86_64

ARG MARIADB_VERSION="11.4.10"
ARG GRIMMORY_VERSION="3.0.1"
ARG S6_OVERLAY_VERSION="3.2.1.0"
ARG ALPINE_VERSION="3.22"

FROM --platform=${BUILDPLATFORM} alpine:${ALPINE_VERSION} AS src
RUN apk --update --no-cache add tar xz
WORKDIR /src

FROM scratch AS openjdk-layer-amd64

ARG OPENJDK_MAJOR_VERSION="25"
ARG OPENJDK_VERSION="25.0.3"
ARG OPENJDK_VERSION_REVISION="9"
ARG OPENJDK_AMD64_CHECKSUM="sha256:ad202c8f8b216800ed0d6581130f92e5680b685ba394ba38e62e7605c3fd9494"
         
ADD \
  --unpack \
  --checksum="${OPENJDK_AMD64_CHECKSUM}" \
    https://github.com/adoptium/temurin${OPENJDK_MAJOR_VERSION}-binaries/releases/download/jdk-${OPENJDK_VERSION}%2B${OPENJDK_VERSION_REVISION}/OpenJDK${OPENJDK_MAJOR_VERSION}U-jre_x64_alpine-linux_hotspot_${OPENJDK_VERSION}_${OPENJDK_VERSION_REVISION}.tar.gz \
    /openjdk/

FROM scratch AS openjdk-layer-arm64

ARG OPENJDK_MAJOR_VERSION="25"
ARG OPENJDK_VERSION="25.0.3"
ARG OPENJDK_VERSION_REVISION="9"
ARG OPENJDK_ARM64_CHECKSUM="sha256:48aa0908d9f4d501c1070ebbc8a4da93ca1f066c41ff2e34a22a34dd3ca2dac1"

ADD \
  --unpack \
  --checksum="${OPENJDK_ARM64_CHECKSUM}" \
    https://github.com/adoptium/temurin${OPENJDK_MAJOR_VERSION}-binaries/releases/download/jdk-${OPENJDK_VERSION}%2B${OPENJDK_VERSION_REVISION}/OpenJDK${OPENJDK_MAJOR_VERSION}U-jre_aarch64_alpine-linux_hotspot_${OPENJDK_VERSION}_${OPENJDK_VERSION_REVISION}.tar.gz \
    /openjdk/

FROM openjdk-layer-${TARGETARCH} AS openjdk-layer

FROM src AS s6-overlay
ARG S6_OVERLAY_VERSION
ARG ARCH

WORKDIR /dist

# add s6 overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C /dist -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${ARCH}.tar.xz /tmp
RUN tar -C /dist -Jxpf /tmp/s6-overlay-${ARCH}.tar.xz

# add s6 optional symlinks
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz /tmp
RUN tar -C /dist -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz /tmp
RUN tar -C /dist -Jxpf /tmp/s6-overlay-symlinks-arch.tar.xz

FROM ghcr.io/grimmory-tools/grimmory:v${GRIMMORY_VERSION} AS grimmory-overlay

FROM alpine:${ALPINE_VERSION} AS run
ARG MARIADB_VERSION
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"

ENV MARIADB_PID="/run/mysqld/mysqld.pid"
ENV MARIADB_DATADIR="/database"
ENV MARIADB_DATABASE="grimmory"
ENV MARIADB_USER="grimmory"

# TODO: Replace with a generated password file if not set
ENV MARIADB_PASSWORD="grimmory"
ENV MARIADB_ROOT_PASSWORD="grimmory"

COPY --from=s6-overlay /dist /

# Copy java over
COPY --from=openjdk-layer /openjdk/*/ "${JAVA_HOME}"

# Copy the grimmory app jar
COPY --from=grimmory-overlay /app/app.jar /app/app.jar

# Copy the kepubify and ffprobe binaries
COPY --from=grimmory-overlay /usr/local/bin/ffprobe /usr/local/bin/kepubify /usr/local/bin/


ENV TZ="UTC"
ENV PUID="1000"
ENV PGID="1000"
ENV S6_VERBOSITY=1

# Create the mariadb data directory
RUN mkdir -p "${MARIADB_DATADIR}"

# Install dependencies needed to run
RUN apk --update --no-cache add \
    bash \
    binutils \
    ca-certificates \
    coreutils \
    grep \
    nginx \
    gawk \
    gettext \
    openssl \
    util-linux

# Install MariaDB
RUN \
  echo "Installing ${MARIADB_VERSION}" && \
  apk --update --no-cache add \
    mariadb=~${MARIADB_VERSION} \
    mariadb-backup=~${MARIADB_VERSION} \
    mariadb-client=~${MARIADB_VERSION} \
    mariadb-common=~${MARIADB_VERSION} \
    mariadb-server-utils=~${MARIADB_VERSION} && \
  rm -rf \
    /tmp/* \
    $HOME/.cache

# Set up the grimmory user
RUN addgroup -g ${PGID} grimmory
RUN adduser -D -H -u ${PUID} -G grimmory -s /bin/sh grimmory

# Copy over the s6 overlay
COPY rootfs /

VOLUME "/databases"
VOLUME "/books"
VOLUME "/bookdrop"

ENTRYPOINT [ "/init" ]

EXPOSE 8080
EXPOSE 3306

HEALTHCHECK \
  --interval=30s \
  --timeout=20s \
  --start-period=10s \
  CMD /usr/local/bin/healthcheck
