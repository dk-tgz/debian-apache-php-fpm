# Use Debian 12 as the base image
FROM debian:12 as builder
LABEL maintainer="Dawid Kalicki kgcgzg36s@mozmail.com"

ARG DEBIAN_FRONTEND=noninteractive
ENV HOME /root
ENV TZ=UTC

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install Apache2, PHP, required PHP extensions, and Supervisor
# Install PHP 8.2 and required extensions
RUN apt-get update -qq  && apt-get upgrade -qq -y
RUN apt-get install -qq -y \
    apache2 \
    apache2-utils \
    software-properties-common \
    supervisor \
    python3-launchpadlib \
    wget
 
RUN add-apt-repository ppa:ondrej/php
RUN apt-get update -qq && apt-get install -qq -y \
    php8.2 \
    php8.2-fpm \
    php8.2-gd \
    php8.2-xml \
    php8.2-mbstring \
    php8.2-intl \
    php8.2-bz2 \
    libapache2-mod-php8.2 \
    php8.2-opcache \
    php8.2-zip \ 
    php8.2-ldap \
    php8.2-gmp \
    php8.2-bcmath \
    php8.2-exif \
    php8.2-sysvsem \
    php8.2-imagic \
    php8.2-memcached \
    php8.2-redis \
    php8.2-apcu \
    php8.2-mysql \
    php8.2-pgsql

RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
    } > /etc/php/8.2/mods-available/opcache.ini

RUN { \
    echo "php_value[upload_max_filesize] = 10M"; \
    echo "error_log = /proc/self/fd/2"; \
    echo "access_log = /proc/self/fd/2@g"; \
    } >> /etc/php/8.2/fpm/pool.d/www.conf

RUN sed -i "s/memory_limit = 128M/memory_limit = 2G/" /etc/php/8.2/fpm/php.ini

RUN ln -sf /dev/stdout /var/log/apache2/access.log \
    && ln -sf /dev/stderr /var/log/apache2/error.log

RUN wget https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_amd64.deb -O /tmp/modpagespeed.deb \
    && dpkg -i /tmp/modpagespeed.deb


RUN a2enmod ssl \
    && a2enmod rewrite \
    && a2enmod headers \
    && a2enmod deflate \
    && a2enmod mime \
    && a2enmod env \
    && a2enmod dir \
    && a2enmod proxy_fcgi setenvif \
    && a2enconf php8.2-fpm 
RUN sed -i -e 's/ModPagespeed on/ModPagespeed off/g' /etc/apache2/mods-available/pagespeed.conf
RUN sed -i 's/ServerTokens OS/ServerTokens Prod/' /etc/apache2/conf-available/security.conf
RUN sed -i 's/ServerSignature On/ServerSignature Off/' /etc/apache2/conf-available/security.conf


# Configure Apache for HTTPS and HTTP/2
COPY ./your-ssl-certificate.crt /etc/ssl/certs/
COPY ./your-private-key.key /etc/ssl/private/
COPY ./your-site.conf /etc/apache2/sites-available/
RUN a2ensite your-site


# Set correct permissions for DokuWiki
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# Cleanup to reduce image size
RUN apt-get autoremove && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Supervisord configuration
COPY ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose ports 80 and 443 for HTTP and HTTPS
EXPOSE 80 443

# Start services managed by Supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

from scratch
COPY --from=builder . .
