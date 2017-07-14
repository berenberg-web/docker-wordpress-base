FROM berenberg/web-base:7.1.7-1.13.3
 
COPY docker/ /

ENV WORDPRESS_VERSION=4.8 \
    WORDPRESS_SHA1=3738189a1f37a03fb9cb087160b457d7a641ccb4

RUN set -ex \
    # install the PHP extensions we need
 && apk add --no-cache --virtual .persistent-deps \
    bash \
    sed \
 && apk add --no-cache --virtual .build-deps \
    autoconf \
		libjpeg-turbo-dev \
		libpng-dev \
		icu-dev \
 && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
 && docker-php-ext-configure intl --enable-intl \
 && docker-php-ext-install \
    gd \
    intl \
    mysqli \
    opcache \
    pdo_mysql \
 &&	runDeps="$( \
  		scanelf --needed --nobanner --recursive /usr/local/lib/php/extensions \
  			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
  			| sort -u \
  			| xargs -r apk info --installed \
  			| sort -u \
  	)" \
 && apk add  --no-cache --virtual .wordpress-phpexts-rundeps $runDeps \
 && apk del .build-deps \
    # download wordpress source
 && curl -o wordpress.tar.gz -fSL "https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz" \
 && echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c - \
 && tar -xzf wordpress.tar.gz -C /usr/src/ \
 && rm wordpress.tar.gz \
 && chown -R www-data:www-data /usr/src/wordpress

ENTRYPOINT ["docker-entrypoint"]

CMD ["php-fpm"]
