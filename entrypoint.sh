#!/bin/sh

echo "[*] Starting bunkerized-php ..."

# execute custom scripts if it's a customized image
for file in /entrypoint.d/* ; do
    [ -f "$file" ] && [ -x "$file" ] && "$file"
done

# trap SIGTERM and SIGINT
function trap_exit() {
	echo "[*] Stopping crond ..."
	pkill -TERM crond
	echo "[*] Stopping php ..."
	pkill -TERM php-fpm
	echo "[*] Stopping syslogd ..."
	pkill -TERM syslogd
	pkill -TERM tail
}
trap "trap_exit" TERM INT

# replace pattern in file
function replace_in_file() {
	# escape slashes
	pattern=$(echo "$2" | sed "s/\//\\\\\//g")
	replace=$(echo "$3" | sed "s/\//\\\\\//g")
	sed -i "s/$pattern/$replace/g" "$1"
}

# install some additional packages if needed
if [ "$APK_ADD" != "" ] ; then
	apk add $APK_ADD
fi

# install some PECL packages if needed
if [ "$PECL_INSTALL" != "" ] ; then
	pecl install $PECL_INSTALL
fi

# enable some extensions if needed
if [ "$PHP_EXT_ENABLE" != "" ] ; then
	docker-php-ext-enable $PHP_EXT_ENABLE
fi

# install some extensions if needed
if [ "$PHP_EXT_INSTALL" != "" ] ; then
	docker-php-ext-install $PHP_EXT_INSTALL
fi

# replace default values
replace_in_file "/usr/local/etc/php-fpm.d/www.conf" "127.0.0.1:9000" "0.0.0.0:9000"

# file paths
PHP_INI_CONF="/usr/local/etc/php/php.ini"
PHP_INI_DIR="/usr/local/etc/php/conf.d"

# copy stub confs
cp /opt/confs/php.ini "$PHP_INI_CONF"
cp /opt/confs/syslog.conf /etc/syslog.conf
cp /opt/confs/logrotate.conf /etc/logrotate.conf
cp /opt/confs/snuffleupagus.rules "${PHP_INI_DIR}/snuffleupagus.rules"

# remove cron jobs
echo "" > /etc/crontabs/root

# set default values
PHP_DOC_ROOT="${PHP_DOC_ROOT-/www}"
PHP_EXPOSE="${PHP_EXPOSE-0}"
PHP_DISPLAY_ERRORS="${PHP_DISPLAY_ERRORS-0}"
PHP_OPEN_BASEDIR="${PHP_OPEN_BASEDIR-/www/:/tmp/uploads/:/tmp/sessions/}"
PHP_ALLOW_URL_FOPEN="${PHP_ALLOW_URL_FOPEN-0}"
PHP_ALLOW_URL_INCLUDE="${PHP_ALLOW_URL_INCLUDE-0}"
PHP_FILE_UPLOADS="${PHP_FILE_UPLOADS-0}"
PHP_UPLOAD_MAX_FILESIZE="${PHP_UPLOAD_MAX_FILESIZE-10M}"
PHP_UPLOAD_TMP_DIR="${PHP_UPLOAD_TMP_DIR-/tmp/uploads}"
PHP_POST_MAX_SIZE="${PHP_POST_MAX_SIZE-10M}"
PHP_DISABLE_FUNCTIONS="${PHP_DISABLE_FUNCTIONS-system, exec, shell_exec, passthru, phpinfo, show_source, highlight_file, popen, proc_open, fopen_with_path, dbmopen, dbase_open, putenv, filepro, filepro_rowcount, filepro_retrieve, posix_mkfifo}"
PHP_SESSION_SAVE_PATH="${PHP_SESSION_SAVE_PATH-/tmp/sessions}"
PHP_SESSION_COOKIE_SECURE="${PHP_SESSION_COOKIE_SECURE-0}"
PHP_SESSION_COOKIE_PATH="${PHP_SESSION_COOKIE_PATH-/}"
PHP_SESSION_COOKIE_HTTPONLY="${PHP_SESSION_COOKIE_HTTPONLY-1}"
PHP_SESSION_COOKIE_SAMESITE="${PHP_SESSION_COOKIE_SAMESITE-Strict}"
PHP_SESSION_NAME="${PHP_SESSION_NAME-random}"
PHP_MEMORY_LIMIT="${PHP_MEMORY_LIMIT-128M}"
USE_SNUFFLEUPAGUS="${USE_SNUFFLEUPAGUS-yes}"
LOGROTATE_MINSIZE="${LOGROTATE_MINSIZE-10M}"
LOGROTATE_MAXAGE="${LOGROTATE_MAXAGE-7}"

# replace values
replace_in_file "$PHP_INI_CONF" "%PHP_EXPOSE%" "$PHP_EXPOSE"
replace_in_file "$PHP_INI_CONF" "%PHP_DISPLAY_ERRORS%" "$PHP_DISPLAY_ERRORS"
replace_in_file "$PHP_INI_CONF" "%PHP_OPEN_BASEDIR%" "$PHP_OPEN_BASEDIR"
replace_in_file "$PHP_INI_CONF" "%PHP_ALLOW_URL_FOPEN%" "$PHP_ALLOW_URL_FOPEN"
replace_in_file "$PHP_INI_CONF" "%PHP_ALLOW_URL_INCLUDE%" "$PHP_ALLOW_URL_INCLUDE"
replace_in_file "$PHP_INI_CONF" "%PHP_FILE_UPLOADS%" "$PHP_FILE_UPLOADS"
replace_in_file "$PHP_INI_CONF" "%PHP_UPLOAD_MAX_FILESIZE%" "$PHP_UPLOAD_MAX_FILESIZE"
replace_in_file "$PHP_INI_CONF" "%PHP_UPLOAD_TMP_DIR%" "$PHP_UPLOAD_TMP_DIR"
replace_in_file "$PHP_INI_CONF" "%PHP_DISABLE_FUNCTIONS%" "$PHP_DISABLE_FUNCTIONS"
replace_in_file "$PHP_INI_CONF" "%PHP_POST_MAX_SIZE%" "$PHP_POST_MAX_SIZE"
replace_in_file "$PHP_INI_CONF" "%PHP_DOC_ROOT%" "$PHP_DOC_ROOT"
replace_in_file "$PHP_INI_CONF" "%PHP_SESSION_SAVE_PATH%" "$PHP_SESSION_SAVE_PATH"
replace_in_file "$PHP_INI_CONF" "%PHP_SESSION_COOKIE_SECURE%" "$PHP_SESSION_COOKIE_SECURE"
replace_in_file "$PHP_INI_CONF" "%PHP_SESSION_COOKIE_PATH%" "$PHP_SESSION_COOKIE_PATH"
replace_in_file "$PHP_INI_CONF" "%PHP_SESSION_COOKIE_HTTPONLY%" "$PHP_SESSION_COOKIE_HTTPONLY"
replace_in_file "$PHP_INI_CONF" "%PHP_SESSION_COOKIE_SAMESITE%" "$PHP_SESSION_COOKIE_SAMESITE"
replace_in_file "$PHP_INI_CONF" "%PHP_SESSION_COOKIE_DOMAIN%" "$PHP_SESSION_COOKIE_DOMAIN"
if [ "$PHP_SESSION_NAME" = "random" ] ; then
	rand_nb=$((10 + RANDOM % 11))
	rand_name=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $rand_nb | head -n 1)
	replace_in_file "$PHP_INI_CONF" "%PHP_SESSION_NAME%" "$rand_name"
else
	replace_in_file "$PHP_INI_CONF" "%PHP_SESSION_NAME%" "$PHP_SESSION_NAME"
fi
replace_in_file "$PHP_INI_CONF" "%PHP_MEMORY_LIMIT%" "$PHP_MEMORY_LIMIT"

# snuffleupagus setup
if [ "$USE_SNUFFLEUPAGUS" = "yes" ] ; then
	replace_in_file "$PHP_INI_CONF" "%SNUFFLEUPAGUS_EXTENSION%" "extension=snuffleupagus.so"
	if [ -f "/snuffleupagus.rules" ] ; then
		replace_in_file "$PHP_INI_CONF" "%SNUFFLEUPAGUS_CONFIG%" "sp.configuration_file=/snuffleupagus.rules"
	else
		replace_in_file "$PHP_INI_CONF" "%SNUFFLEUPAGUS_CONFIG%" "sp.configuration_file=${PHP_INI_DIR}/snuffleupagus.rules"
	fi
else
	replace_in_file "$PHP_INI_CONF" "%SNUFFLEUPAGUS_EXTENSION%" ""
	replace_in_file "$PHP_INI_CONF" "%SNUFFLEUPAGUS_CONFIG%" ""
fi

# start syslogd
syslogd -S

# setup logrotate
replace_in_file "/etc/logrotate.conf" "%LOGROTATE_MAXAGE%" "$LOGROTATE_MAXAGE"
replace_in_file "/etc/logrotate.conf" "%LOGROTATE_MINSIZE%" "$LOGROTATE_MINSIZE"
echo "0 0 * * * logrotate -f /etc/logrotate.conf > /dev/null 2>&1" >> /etc/crontabs/root

# start crond
crond

# start PHP
PHP_INI_SCAN_DIR=:/php.d/:/usr/local/etc/php/conf.d/ php-fpm
if [ ! -f "/var/log/php-fpm.log" ] ; then
	touch /var/log/php-fpm.log
fi
if [ ! -f "/var/log/php.log" ] ; then
	touch /var/log/php.log
fi
tail -f /var/log/php-fpm.log /var/log/php.log &
wait $!

# sigterm trapped
echo "[*] bunkerized-php stopped"
exit 0
