# syntax=docker/dockerfile:1

ARG LIBSIG_VERSION=3.0.3
ARG CARES_VERSION=1.34.5
ARG CURL_VERSION=8.14.1
ARG MKTORRENT_VERSION=v1.1

ARG LIBTORRENT_VERSION=v0.15.5
ARG RTORRENT_VERSION=v0.15.5

ARG RUTORRENT_VERSION=v5.2.10

ARG DUMP_TORRENT_VERSION=v1.7.0

ARG ALPINE_VERSION=3.22

FROM alpine:${ALPINE_VERSION} AS src
RUN apk --update --no-cache add curl git tar tree sed xz
WORKDIR /src

FROM src AS src-libsig
ARG LIBSIG_VERSION
RUN curl -sSL "https://download.gnome.org/sources/libsigc%2B%2B/3.0/libsigc%2B%2B-${LIBSIG_VERSION}.tar.xz" | tar xJv --strip 1

FROM src AS src-cares
ARG CARES_VERSION
RUN curl -sSL "https://github.com/c-ares/c-ares/releases/download/v${CARES_VERSION}/c-ares-${CARES_VERSION}.tar.gz" | tar xz --strip 1

FROM src AS src-curl
ARG CURL_VERSION
RUN curl -sSL "https://curl.se/download/curl-${CURL_VERSION}.tar.gz" | tar xz --strip 1

FROM src AS src-libtorrent
RUN git init . && git remote add origin "https://github.com/rakshasa/libtorrent.git"
ARG LIBTORRENT_VERSION
RUN git fetch origin "${LIBTORRENT_VERSION}" && git checkout -q FETCH_HEAD

FROM src AS src-rtorrent
RUN git init . && git remote add origin "https://github.com/rakshasa/rtorrent.git"
ARG RTORRENT_VERSION
RUN git fetch origin "${RTORRENT_VERSION}" && git checkout -q FETCH_HEAD

FROM src AS src-mktorrent
RUN git init . && git remote add origin "https://github.com/pobrn/mktorrent.git"
ARG MKTORRENT_VERSION
RUN git fetch origin "${MKTORRENT_VERSION}" && git checkout -q FETCH_HEAD

FROM src AS src-rutorrent
RUN git init . && git remote add origin "https://github.com/Novik/ruTorrent.git"
ARG RUTORRENT_VERSION
RUN git fetch origin "${RUTORRENT_VERSION}" && git checkout -q FETCH_HEAD
RUN rm -rf .git* conf/users plugins/_cloudflare plugins/mediainfo plugins/screenshots share

FROM src AS src-dump-torrent
RUN git init . && git remote add origin "https://github.com/tomcdj71/dumptorrent.git"
ARG DUMP_TORRENT_VERSION
RUN git fetch origin "${DUMP_TORRENT_VERSION}" && git checkout -q FETCH_HEAD
RUN sed -i '1i #include <sys/time.h>' src/scrapec.c
RUN rm -rf .git*

FROM alpine:${ALPINE_VERSION} AS builder

RUN apk --update --no-cache add \
    autoconf \
    automake \
    binutils \
    brotli-dev \
    build-base \
    cppunit-dev \
    cmake \
    gd-dev \
    libpsl-dev \
    libtool \
    libxslt-dev \
    linux-headers \
    ncurses-dev \
    nghttp2-dev \
    openssl-dev \
    pcre-dev \
    php84-dev \
    php84-pear \
    tar \
    tree \
    xz \
    zlib-dev


RUN ln -s /usr/bin/php84 /usr/bin/php && ln -s /usr/bin/php-config84 /usr/bin/php-config

ENV DIST_PATH="/dist"

WORKDIR /usr/local/src/libsig
COPY --from=src-libsig /src .
RUN ./configure
RUN make -j$(nproc)
RUN make install -j$(nproc)
RUN make DESTDIR=${DIST_PATH} install -j$(nproc)
RUN tree ${DIST_PATH}

WORKDIR /usr/local/src/cares
COPY --from=src-cares /src .
RUN cmake . -D CARES_SHARED=ON -D CMAKE_BUILD_TYPE:STRING="Release" -D CMAKE_C_FLAGS_RELEASE:STRING="-O3 -flto=\"$(nproc)\" -pipe"
RUN cmake --build . --clean-first --parallel $(nproc)
RUN make install -j$(nproc)
RUN make DESTDIR=${DIST_PATH} install -j$(nproc)
RUN tree ${DIST_PATH}

WORKDIR /usr/local/src/curl
COPY --from=src-curl /src .
RUN cmake . -D ENABLE_ARES=ON -D CURL_LTO=ON -D CURL_USE_OPENSSL=ON -D CURL_BROTLI=ON -D CURL_ZSTD=ON -D BUILD_SHARED_LIBS=ON -D CMAKE_BUILD_TYPE:STRING="Release" -D CMAKE_C_FLAGS_RELEASE:STRING="-O3 -flto=\"$(nproc)\" -pipe"
RUN cmake --build . --clean-first --parallel $(nproc)
RUN make install -j$(nproc)
RUN make DESTDIR=${DIST_PATH} install -j$(nproc)
RUN tree ${DIST_PATH}

WORKDIR /usr/local/src/rtorrent/libtorrent
COPY --from=src-libtorrent /src .
RUN autoreconf -vfi
RUN ./configure --enable-aligned --disable-instrumentation
RUN make -j$(nproc) CXXFLAGS="-w -O3 -flto -Werror=odr -Werror=lto-type-mismatch -Werror=strict-aliasing"
RUN make install -j$(nproc)
RUN make DESTDIR=${DIST_PATH} install -j$(nproc)
RUN tree ${DIST_PATH}

WORKDIR /usr/local/src/rtorrent/rtorrent
COPY --from=src-rtorrent /src .
RUN autoreconf -vfi
RUN ./configure --with-xmlrpc-tinyxml2 --with-ncurses
RUN make -j$(nproc) CXXFLAGS="-w -O3 -flto -Werror=odr -Werror=lto-type-mismatch -Werror=strict-aliasing"
RUN make install -j$(nproc)
RUN make DESTDIR=${DIST_PATH} install -j$(nproc)
RUN tree ${DIST_PATH}

WORKDIR /usr/local/src/mktorrent
COPY --from=src-mktorrent /src .
RUN echo "CC = gcc" >> Makefile	
RUN echo "CFLAGS = -w -flto -O3" >> Makefile
RUN echo "USE_PTHREADS = 1" >> Makefile
RUN echo "USE_OPENSSL = 1" >> Makefile
RUN make -j$(nproc)
RUN make install -j$(nproc)
RUN make DESTDIR=${DIST_PATH} install -j$(nproc)
RUN tree ${DIST_PATH}

WORKDIR /usr/local/src/dump-torrent
COPY --from=src-dump-torrent /src .
RUN cmake -B build/ -D CMAKE_CXX_COMPILER=g++ -D CMAKE_C_COMPILER=gcc -D CMAKE_BUILD_TYPE=Release -D CMAKE_CXX_FLAGS="-O3 -flto" -D CMAKE_C_FLAGS="-O3 -flto" -S .
RUN cmake --build build/ --config Release --clean-first --parallel $(nproc)
RUN cp build/dumptorrent build/scrapec ${DIST_PATH}/usr/local/bin
RUN tree ${DIST_PATH}

FROM alpine:${ALPINE_VERSION}

COPY --from=builder /dist /
COPY --from=src-rutorrent --chown=nobody:nogroup /src /var/www/rutorrent

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS="2" \
  S6_KILL_GRACETIME="10000" \
  TZ="UTC"

# increase rmem_max and wmem_max for rTorrent configuration
RUN echo "net.core.rmem_max = 67108864" >> /etc/sysctl.conf \
  && echo "net.core.wmem_max = 67108864" >> /etc/sysctl.conf \
  && sysctl -p

# unrar package is not available since alpine 3.15
# dhclient package is not available since alpine 3.21
RUN echo "@314 http://dl-cdn.alpinelinux.org/alpine/v3.14/main" >> /etc/apk/repositories \
  && echo "@320 http://dl-cdn.alpinelinux.org/alpine/v3.20/main" >> /etc/apk/repositories \
  && apk --update --no-cache add unrar@314 dhclient@320
  
RUN apk --update --no-cache add \
    s6-overlay \
    apache2-utils \
    bash \
    bind-tools \
    binutils \
    brotli \
    ca-certificates \
    coreutils \
    findutils \
    grep \
    gzip \
    libstdc++ \
    ncurses \
    nginx \
    openssl \
    php84 \
    php84-bcmath \
    php84-ctype \
    php84-curl \
    php84-dom \
    php84-fileinfo \
    php84-fpm \
    php84-mbstring \
    php84-openssl \
    php84-phar \
    php84-posix \
    php84-session \
    php84-sockets \
    php84-xml \
    php84-zip \
    shadow \
    sox \
    tar \
    tzdata \
    unzip \
    util-linux \
    zip \
  && ln -s /usr/bin/php84 /usr/bin/php \
  && rm -rf /tmp/*

COPY rootfs /

VOLUME [ "/data", "/passwd" ]
ENTRYPOINT [ "/init" ]

HEALTHCHECK --interval=30s --timeout=20s --start-period=10s \
  CMD /usr/local/bin/healthcheck
