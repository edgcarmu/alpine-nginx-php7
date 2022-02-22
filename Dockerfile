FROM alpine:3.13
LABEL Maintainer="Fabian Carvajal <inbox@edgcarmu.me>" \
      Description="Lightweight container with Nginx 1.18 & PHP 7.4 based on Alpine Linux."

# Install packages and remove default server definition
RUN apk --no-cache add php7 php7-dev php7-fpm php7-opcache php7-mysqli php7-json php7-openssl php7-curl \
    php7-zlib php7-xml php7-phar php7-intl php7-dom php7-xmlreader php7-xmlwriter php7-ctype php7-session \
    php7-sysvshm php7-sysvsem php7-sysvmsg php7-sqlite3 php7-simplexml php7-sodium php7-soap php7-ffi php7-pecl-imagick \
    php7-pcntl php7-pgsql php7-posix php7-redis php7-shmop php7-sockets php7-zip php7-pear php7-xsl \
    php7-gmp php7-bcmath php7-tokenizer php7-iconv php7-calendar php7-exif php7-ftp php7-gettext php7-imap \
    php7-pdo php7-pdo_mysql php7-pdo_sqlite php7-pdo_pgsql php7-mysqlnd php7-fileinfo \
    php7-msgpack php7-memcached \
    php7-mbstring php7-gd nginx supervisor curl yarn && \
    rm /etc/nginx/conf.d/default.conf

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY config/php.ini /etc/php7/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup document root
RUN mkdir -p /var/www/html

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/html && \
  chown -R nobody.nobody /run && \
  chown -R nobody.nobody /var/lib/nginx && \
  chown -R nobody.nobody /var/log/nginx

# Switch to use a non-root user from here on
USER nobody

# Add application
WORKDIR /var/www/html
COPY --chown=nobody src/ /var/www/html/

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
