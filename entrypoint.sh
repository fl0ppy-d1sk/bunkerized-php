#!/bin/sh

echo "[*] Starting bunkerized-php ..."

# trap SIGTERM and SIGINT
function trap_exit() {
	echo "[*] Stopping crond ..."
	pkill -TERM crond
	echo "[*] Stopping php ..."
	pkill -TERM php-fpm7
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

# copy stub confs
cp /opt/confs/php.ini /etc/php7/php.ini
cp /opt/confs/syslog.conf /etc/syslog.conf
cp /opt/confs/logrotate.conf /etc/logrotate.conf
cp /opt/confs/snuffleupagus.rules /etc/php7/conf.d/snuffleupagus.rules

# remove cron jobs
echo "" > /etc/crontabs/root

# set default values
PHP_DOC_ROOT="${ROOT_FOLDER-/www}"
PHP_EXPOSE="${PHP_EXPOSE-no}"
PHP_DISPLAY_ERRORS="${PHP_DISPLAY_ERRORS-no}"
PHP_OPEN_BASEDIR="${PHP_OPEN_BASEDIR-/www/:/tmp/}"
PHP_ALLOW_URL_FOPEN="${PHP_ALLOW_URL_FOPEN-no}"
PHP_ALLOW_URL_INCLUDE="${PHP_ALLOW_URL_INCLUDE-no}"
PHP_FILE_UPLOADS="${PHP_FILE_UPLOADS-no}"
PHP_UPLOAD_MAX_FILESIZE="${PHP_UPLOAD_MAX_FILESIZE-10M}"
PHP_POST_MAX_SIZE="${PHP_POST_MAX_SIZE-10M}"
PHP_DISABLE_FUNCTIONS="${PHP_DISABLE_FUNCTIONS-system, exec, shell_exec, passthru, phpinfo, show_source, highlight_file, popen, proc_open, fopen_with_path, dbmopen, dbase_open, putenv, filepro, filepro_rowcount, filepro_retrieve, posix_mkfifo}"
USE_SNUFFLEUPAGUS="{USE_SNUFFLEUPAGUS-yes}"
LOGROTATE_MINSIZE="${LOGROTATE_MINSIZE-10M}"
LOGROTATE_MAXAGE="${LOGROTATE_MAXAGE-7}"

# install additional modules if needed
if [ "$ADDITIONAL_MODULES" != "" ] ; then
	apk add $ADDITIONAL_MODULES
fi

# replace values
if [ "$PHP_EXPOSE" = "yes" ] ; then
	replace_in_file "/etc/php7/php.ini" "%PHP_EXPOSE%" "On"
else
	replace_in_file "/etc/php7/php.ini" "%PHP_EXPOSE%" "Off"
fi
if [ "$PHP_DISPLAY_ERRORS" = "yes" ] ; then
	replace_in_file "/etc/php7/php.ini" "%PHP_DISPLAY_ERRORS%" "On"
else
	replace_in_file "/etc/php7/php.ini" "%PHP_DISPLAY_ERRORS%" "Off"
fi
replace_in_file "/etc/php7/php.ini" "%PHP_OPEN_BASEDIR%" "$PHP_OPEN_BASEDIR"
if [ "$PHP_ALLOW_URL_FOPEN" = "yes" ] ; then
	replace_in_file "/etc/php7/php.ini" "%PHP_ALLOW_URL_FOPEN%" "On"
else
	replace_in_file "/etc/php7/php.ini" "%PHP_ALLOW_URL_FOPEN%" "Off"
fi
if [ "$PHP_ALLOW_URL_INCLUDE" = "yes" ] ; then
	replace_in_file "/etc/php7/php.ini" "%PHP_ALLOW_URL_INCLUDE%" "On"
else
	replace_in_file "/etc/php7/php.ini" "%PHP_ALLOW_URL_INCLUDE%" "Off"
fi
if [ "$PHP_FILE_UPLOADS" = "yes" ] ; then
	replace_in_file "/etc/php7/php.ini" "%PHP_FILE_UPLOADS%" "On"
else
	replace_in_file "/etc/php7/php.ini" "%PHP_FILE_UPLOADS%" "Off"
fi
replace_in_file "/etc/php7/php.ini" "%PHP_UPLOAD_MAX_FILESIZE%" "$PHP_UPLOAD_MAX_FILESIZE"
replace_in_file "/etc/php7/php.ini" "%PHP_DISABLE_FUNCTIONS%" "$PHP_DISABLE_FUNCTIONS"
replace_in_file "/etc/php7/php.ini" "%PHP_POST_MAX_SIZE%" "$PHP_POST_MAX_SIZE"
replace_in_file "/etc/php7/php.ini" "%PHP_DOC_ROOT%" "$PHP_DOC_ROOT"

# snuffleupagus setup
if [ "$USE_SNUFFLEUPAGUS" = "yes" ] ; then
	replace_in_file "/etc/php7/php.ini" "%SNUFFLEUPAGUS_EXTENSION%" "extension=snuffleupagus.so"
	if [ -f "/snuffleupagus.rules" ] ; then
		replace_in_file "/etc/php7/php.ini" "%SNUFFLEUPAGUS_CONFIG%" "sp.configuration_file=/snuffleupagus.rules"
	else
		replace_in_file "/etc/php7/php.ini" "%SNUFFLEUPAGUS_CONFIG%" "sp.configuration_file=/etc/php7/conf.d/snuffleupagus.rules"
	fi
else
	replace_in_file "/etc/php7/php.ini" "%SNUFFLEUPAGUS_EXTENSION%" ""
	replace_in_file "/etc/php7/php.ini" "%SNUFFLEUPAGUS_CONFIG%" ""
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
replace_in_file "/etc/php7/php-fpm.d/www.conf" "user = nobody" "user = php"
replace_in_file "/etc/php7/php-fpm.d/www.conf" "group = nobody" "group = php"
PHP_INI_SCAN_DIR=:/php.d/ php-fpm7
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
