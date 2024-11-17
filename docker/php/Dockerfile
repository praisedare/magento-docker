FROM php:8.2-fpm

# Install dependencies
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libmagickwand-dev \
    libpng-dev \
    libwebp-dev \
    libxslt1-dev \
    libzip-dev \
    unzip \
    git \
    cron \
    gosu \
    procps \
    default-mysql-client

# Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp
RUN docker-php-ext-install \
    bcmath \
    gd \
    intl \
    opcache \
    pdo_mysql \
    soap \
    xsl \
    zip \
    sockets

# Install additional extensions
RUN pecl install redis imagick \
    && docker-php-ext-enable redis imagick

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Configure PHP
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

# Prepare cron directory and configuration
RUN mkdir -p /var/run/crond && \
    chown www-data:www-data /var/run/crond

# Copy cron template (will be activated post-install)
COPY docker/php/crontab.template /etc/cron.d/magento.template
RUN chmod 0644 /etc/cron.d/magento.template

WORKDIR /var/www/html

# Install Magento
ARG MAGENTO_VERSION
ARG COMPOSER_AUTH
ENV MAGENTO_VERSION=${MAGENTO_VERSION}

# Copy composer auth if provided
COPY docker/php/auth.json /root/.composer/auth.json

# Switch to www-data user for Composer operations
# USER www-data

# Install Magento
RUN set -eux; \
    composer create-project --repository-url=https://repo.magento.com/ \
        magento/project-community-edition="${MAGENTO_VERSION}" .

# Set up directory structure and permissions
RUN set -eux; \
    mkdir -p \
        generated \
        pub/static \
        pub/media \
        var \
        app/etc

# Switch back to root for final permission setup
USER root

# Set correct permissions
RUN set -eux; \
    find . -type d -exec chmod 775 {} + && \
    find . -type f -exec chmod 664 {} + && \
    find ./bin -type f -exec chmod 775 {} + && \
    chmod -R 775 \
        generated \
        pub/static \
        pub/media \
        var \
        app/etc && \
    chown -R www-data:www-data .

# Add installation and cron setup scripts
COPY docker/php/install-magento.sh /usr/local/bin/install-magento
COPY docker/php/setup-cron.sh /usr/local/bin/setup-cron
RUN chmod +x /usr/local/bin/install-magento /usr/local/bin/setup-cron \
    && chown www-data:www-data /usr/local/bin/install-magento /usr/local/bin/setup-cron

RUN sed -i \
    -e "s/user = www-data/user = www-data/g" \
    -e "s/group = www-data/group = www-data/g" \
    /usr/local/etc/php-fpm.d/www.conf

# Add entrypoint script
COPY docker/php/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]
