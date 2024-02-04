# Use Debian 12 as the base image
FROM debian:12 as builder

ARG GIT_COMMIT
ARG DEBIAN_FRONTEND=noninteractive
ENV HOME=/root \
    TZ=UTC
LABEL version="${GIT_COMMIT}"
LABEL maintainer="Dawid Kalicki kgcgzg36s@mozmail.com"

# Set the timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install Apache2, PHP, required PHP extensions, and Supervisor
RUN apt-get update -qq && apt-get upgrade -qq -y && \
    apt-get install -qq -y apache2 apache2-utils software-properties-common supervisor wget python3-launchpadlib && \
    add-apt-repository ppa:ondrej/php && \
    apt-get update -qq && apt-get install -qq -y \
    php8.2 php8.2-fpm php8.2-gd php8.2-xml php8.2-mbstring php8.2-intl php8.2-bz2 \
    libapache2-mod-php8.2 php8.2-opcache php8.2-zip php8.2-ldap php8.2-gmp php8.2-bcmath \
    php8.2-exif php8.2-sysvsem php8.2-imagic php8.2-memcached php8.2-redis php8.2-apcu \
    php8.2-mysql php8.2-pgsql

# Configure PHP
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
    } > /etc/php/8.2/mods-available/opcache.ini

# Configure PHP-FPM pool settings
COPY config/php/www.conf /etc/php/8.2/fpm/pool.d/www.conf
RUN sed -i "s/memory_limit = 128M/memory_limit = 2G/" /etc/php/8.2/fpm/php.ini

# Configure Apache logs to use stdout and stderr
RUN ln -sf /dev/stdout /var/log/apache2/access.log && \
    ln -sf /dev/stderr /var/log/apache2/error.log

# Install mod-pagespeed
RUN wget https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_amd64.deb -O /tmp/modpagespeed.deb && \
    dpkg -i /tmp/modpagespeed.deb

# Enable Apache modules and configuration
RUN a2enmod ssl rewrite headers deflate mime env dir proxy_fcgi setenvif && \
    a2enconf php8.2-fpm && \
    sed -i -e 's/ModPagespeed on/ModPagespeed off/g' /etc/apache2/mods-available/pagespeed.conf && \
    sed -i 's/ServerTokens OS/ServerTokens Prod/' /etc/apache2/conf-available/security.conf && \
    sed -i 's/ServerSignature On/ServerSignature Off/' /etc/apache2/conf-available/security.conf

# Configure Apache for HTTPS and HTTP/2
COPY ssl/your-ssl-certificate.crt /etc/ssl/certs/
COPY ssl/your-private-key.key /etc/ssl/private/
COPY config/apache//your-site.conf /etc/apache2/sites-available/
RUN a2ensite your-site

# Set correct permissions for the web root
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# Cleanup to reduce image size
RUN apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Supervisord configuration
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf



FROM scratch 
COPY --from=builder . .

EXPOSE 80 443
# Start services managed by Supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
