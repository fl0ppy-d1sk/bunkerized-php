FROM alpine

RUN apk --no-cache add php7-fpm && \
    chmod +x /opt/entrypoint.sh && \
    adduser -h /dev/null -g '' -s /sbin/nologin -D -H php && \
    chmod +x /opt/snuffleupagus.sh && \
    /opt/snuffleupagus.sh

COPY entrypoint.sh /opt/entrypoint.sh
COPY confs/ /opt/confs
COPY snuffleupagus.sh /opt/snuffleupagus.sh

VOLUME /www /php-fpm.d /php.d /entrypoint.d

EXPOSE 9000/tcp

ENTRYPOINT ["/opt/entrypoint.sh"]
