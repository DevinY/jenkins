FROM jenkins/jenkins:lts 

USER root
RUN apt-get update \
        && apt-get install -y sudo rsync build-essential

# persistent / runtime deps
ENV PHPIZE_DEPS \
    autoconf \
    dpkg-dev \
    file \
    g++ \
    gcc \
    libc-dev \
    libpcre3-dev \
    make \
    pkg-config \
    re2c

RUN apt-get update && apt-get install -y \
    $PHPIZE_DEPS \
    ca-certificates \
    curl \
    libedit2 \
    libsqlite3-0 \
    libxml2 \
    xz-utils \
    sudo \
    cron \
    git \
    wget \
    python \
    vim \
    unzip \
    mysql-client \
    zip \
    libbz2-dev \
    libgd2-dev \
    libpng-dev \
    libjpeg-dev \
    libgif-dev \
    supervisor \
    --no-install-recommends && rm -r /var/lib/apt/lists/*

ENV PHP_INI_DIR /usr/local/etc/php
RUN mkdir -p $PHP_INI_DIR/conf.d

# Apply stack smash protection to functions using local buffers and alloca()
# Make PHP's main executable position-independent (improves ASLR security mechanism, and has no performance impact on x86_64)
# Enable optimization (-O2)
# Enable linker optimization (this sorts the hash buckets to improve cache locality, and is non-default)
# Adds GNU HASH segments to generated executables (this is used if present, and is much faster than sysv hash; in this configuration, sysv hash is also generated)
# https://github.com/docker-library/php/issues/272
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie"

ENV GPG_KEYS 1729F83938DA44E27BA0F4D3DBDB397470D12172 B1B44D8F021E4E2D6021E995DC9FF8D3EE5AF27F 

ENV PHP_VERSION 7.2.6
ENV PHP_URL="https://secure.php.net/get/php-7.2.6.tar.xz/from/this/mirror" PHP_ASC_URL="https://secure.php.net/get/php-7.2.6.tar.xz.asc/from/this/mirror"
ENV PHP_SHA256="1f004e049788a3effc89ef417f06a6cf704c95ae2a718b2175185f2983381ae7" PHP_MD5=""

RUN set -xe; \
\
fetchDeps=''; \
if ! command -v gpg > /dev/null; then \
fetchDeps="$fetchDeps \
dirmngr \
gnupg2 \
"; \
fi; \
apt-get update; \
apt-get install -y --no-install-recommends $fetchDeps; \
rm -rf /var/lib/apt/lists/*; \
\
mkdir -p /usr/src; \
cd /usr/src; \
\
wget -O php.tar.xz "$PHP_URL"; \
\
if [ -n "$PHP_SHA256" ]; then \
echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c -; \
fi; \
if [ -n "$PHP_MD5" ]; then \
echo "$PHP_MD5 *php.tar.xz" | md5sum -c -; \
fi; \
\
if [ -n "$PHP_ASC_URL" ]; then \
wget -O php.tar.xz.asc "$PHP_ASC_URL"; \
export GNUPGHOME="$(mktemp -d)"; \
for key in $GPG_KEYS; do \
gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
done; \
gpg --batch --verify php.tar.xz.asc php.tar.xz; \
rm -rf "$GNUPGHOME"; \
fi; \
\
apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $fetchDeps

COPY docker-php-source /usr/local/bin/

RUN set -xe \
&& buildDeps=" \
$PHP_EXTRA_BUILD_DEPS \
libcurl4-openssl-dev \
libedit-dev \
libsqlite3-dev \
libssl-dev \
libxml2-dev \
zlib1g-dev \
" \
&& apt-get update && apt-get install -y $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/* \
&& export CFLAGS="$PHP_CFLAGS" \
CPPFLAGS="$PHP_CPPFLAGS" \
LDFLAGS="$PHP_LDFLAGS" \
&& docker-php-source extract \
&& cd /usr/src/php \
&& gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
&& debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)" \
# https://bugs.php.net/bug.php?id=74125
&& if [ ! -d /usr/include/curl ]; then \
ln -sT "/usr/include/$debMultiarch/curl" /usr/local/include/curl; \
fi \
&& ./configure \
--build="$gnuArch" \
--with-config-file-path="$PHP_INI_DIR" \
--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
--disable-cgi \
\
# --enable-ftp is included here because ftp_ssl_connect() needs ftp to be compiled statically (see https://github.com/docker-library/php/issues/236)
--enable-ftp \
# --enable-mbstring is included here because otherwise there's no way to get pecl to use it properly (see https://github.com/docker-library/php/issues/195)
--enable-mbstring \
#Include Zip read/write support
--enable-zip \
--enable-opcache-file \
--with-bz2 \
--with-gettext \
--enable-sockets \
--enable-pcntl \
--enable-phpdbg-debug \
--enable-debug \
# --enable-mysqlnd is included here because it's harder to compile after the fact than extensions are (since it's a plugin for several extensions, not an extension in itself)
--enable-mysqlnd \
--enable-exif \
--enable-sqlite-utf8 \
--enable-zip \
--enable-pcntl \
\
--with-curl \
--with-libedit \
--with-openssl \
--with-zlib \
--with-mysqli \
--with-pdo-mysql \
--with-gd \
--with-jpeg-dir \
--with-png-dir= \
--with-gif-dir \
\
# bundled pcre is too old for s390x (which isn't exactly a good sign)
# /usr/src/php/ext/pcre/pcrelib/pcre_jit_compile.c:65:2: error: #error Unsupported architecture
--with-pcre-regex=/usr \
--with-libdir="lib/$debMultiarch" \
\
$PHP_EXTRA_CONFIGURE_ARGS \
&& make -j "$(nproc)" \
&& make install \
&& { find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; } \
&& make clean \
&& cd / \
&& docker-php-source delete \
\
&& apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps \
\
# https://github.com/docker-library/php/issues/443
&& pecl update-channels \
&& rm -rf /tmp/pear ~/.pearrc


WORKDIR /var/jenkins_home/workspace

#安裝composer
RUN EXPECTED_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig); \
                       php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
                       ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');"); \
                       php composer-setup.php; \
                       php -r "unlink('composer-setup.php');"; \
                       mv composer.phar /usr/local/bin/composer; \
                       echo 'export TERM=xterm-256color' >> /root/.bashrc; \
                       echo 'export PATH=/root/.composer/vendor/bin:$PATH' >> /root/.bashrc;  

RUN  rm -rf /var/lib/apt/lists/*
RUN echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers

USER jenkins
COPY plugins.txt /usr/share/jenkins/plugins.txt
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/plugins.txt
