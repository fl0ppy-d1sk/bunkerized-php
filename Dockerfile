FROM php:fpm-alpine

RUN rm -f /usr/local/etc/php-fpm.d/*docker.conf

COPY snuffleupagus.sh /opt/snuffleupagus.sh
RUN chmod +x /opt/snuffleupagus.sh && /opt/snuffleupagus.sh

COPY entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh
COPY confs/ /opt/confs

VOLUME /www /php-fpm.d /php.d /entrypoint.d

ENTRYPOINT ["/opt/entrypoint.sh"]
