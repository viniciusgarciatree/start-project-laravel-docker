# Use a imagem oficial do PHP-FPM com Alpine 8.1
FROM php:8.3-fpm-alpine
    LABEL maintainer="Vinícius Garcia <viniciusgarciatree@gmail.com>"
    
    # Atualize os pacotes e instale as dependências necessárias
    RUN apk update \
        && apk add --no-cache \
            bash \
            curl \
            libpng-dev \
            libjpeg-turbo-dev \
            libwebp-dev \
            libxpm-dev \
            libxml2-dev \
            zip \
            unzip \
            git \
            oniguruma-dev \
            openssl-dev \
            npm \
            postgresql-dev

    # Instale as extensões do PHP necessárias para o Laravel e o PostgreSQL
    RUN docker-php-ext-install pdo \
        pdo_mysql \
        mbstring \
        exif \
        pcntl \
        bcmath \
        gd \
        opcache \
        pdo_pgsql
    
    # Configurante PHP extensions
    RUN docker-php-ext-configure intl
    
    # Redis
    RUN apk --no-cache add pcre-dev ${PHPIZE_DEPS} \
        && pecl install redis \
        && docker-php-ext-enable redis \
        && apk del pcre-dev ${PHPIZE_DEPS} \
        && rm -rf /tmp/pear

    # Configure PHP
    RUN sed -i -e "s/upload_max_filesize = .*/upload_max_filesize = 100M/g" \
        -e "s/post_max_size = .*/post_max_size = 100M/g" \
        -e "s/memory_limit = .*/memory_limit = 512M/g" \
        -e "s/expose_php = .*/expose_php = 0/g" \
        -e "s/variables_order = .*/variables_order = \"GPCS\"/g" \
        /usr/local/etc/php/php.ini-production \
        && cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini

    # Configure o diretório de trabalho
    WORKDIR /var/www

    # Instale o Composer
    RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

    # Set timezone
    RUN echo "UTC" > /etc/timezone
    ARG TZ=UTC

    # Install nginx e supervisor
    RUN apk add nginx \
        supervisor \
        && mkdir -p /run/nginx

    # Debugger
    RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
        && apk add --update linux-headers \
        && pecl install xdebug \
        && docker-php-ext-enable xdebug \
        && apk del -f .build-deps

    RUN echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/xdebug.ini \
        && echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/xdebug.ini \
        && echo "xdebug.log=/var/log/xdebug.log" >> /usr/local/etc/php/conf.d/xdebug.ini \
        && echo "xdebug.discover_client_host=1" >> /usr/local/etc/php/conf.d/xdebug.ini \
        && echo "xdebug.client_host=127.0.0.1" >> /usr/local/etc/php/conf.d/xdebug.ini \
        && echo "xdebug.client_port=9003" >> /usr/local/etc/php/conf.d/xdebug.ini

    WORKDIR /var/www

    # Copie os arquivos do projeto Laravel para o contêiner
    ADD ./src /var/www

    # Create folter defaults
    RUN mkdir -p \
        storage/framework/{sessions,views,cache} \
        storage/logs \
        bootstrap/cache

    # Defina as permissões corretas para os arquivos
    RUN chown -R www-data:www-data storage \
        && chmod -R 775 storage \
        && chown -R www-data:www-data bootstrap/cache \
        && chmod -R 775 bootstrap/cache

    COPY nginx-site.conf /etc/nginx/http.d/default.conf
    COPY entrypoint.sh /etc/entrypoint.sh

    RUN chmod +x /etc/entrypoint.sh

    EXPOSE 80
    EXPOSE 9000

    # Comando para iniciar o PHP-FPM
    CMD ["php-fpm"]

    ENTRYPOINT ["/etc/entrypoint.sh"]

    CMD ["php", "-S", "0.0.0.0:9000", "-t", "public/"]

    HEALTHCHECK --start-period=5s --interval=2s --timeout=5s --retries=8 CMD php || exit 1
