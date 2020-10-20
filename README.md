# bunkerized-php

<img src="https://github.com/bunkerity/bunkerized-php/blob/master/logo.png?raw=true" width="425" />

<img src="https://img.shields.io/badge/PHP-7.4.11-blue" /> <img src="https://img.shields.io/docker/cloud/build/bunkerity/bunkerized-php" /> <img src="https://img.shields.io/github/last-commit/bunkerity/bunkerized-php" />

php-fpm Docker image secure by default.

Avoid the hassle of following security best practices each time you need a PHP-FPM instance. bunkerized-php provides generic security configs, settings and tools so you don't need to do it yourself.

Non-exhaustive list of features :
- Prevent PHP leaks : version, errors, warnings, ...
- Disable dangerous functions : system, exec, shell_exec, ...
- Limit files accessed by PHP via open_basedir
- State-of-the-art session cookie security : HttpOnly, SameSite, ...
- Integrated [Snuffleupagus](https://snuffleupagus.readthedocs.io) security module
- Easy to configure with environment variables

# Table of contents

# Quickstart guide

## General usage

```
docker run --name myphp --network mynet -v /path/to/web/files:/www bunkerity/bunkerized-php
```

Any container on the network *mynet* can contact the PHP-FPM instance using the *myphp* FQDN.

Web files must be in the /www folder inside the container.

## In combination with bunkerized-nginx

[bunkerized-nginx](https://github.com/bunkerity/bunkerized-nginx) is a nginx Docker image secure by default. It gives you nice features like Let's Encrypt automation, integrated ModSecurity, automatic fail2ban, bot detection, ... and much more.

```
docker network create mynet
docker run --network mynet -v /path/to/web/files:/www -e REMOTE_PHP=myphp -e REMOTE_PHP_PATH=/www bunkerity/bunkerized-nginx
docker run --name myphp --network mynet -v /path/to/web/files:/www bunkerity/bunkerized-php
```

## Enable file uploads

```
docker run --network mynet -v /path/to/web/files:/www -e PHP_FILE_UPLOADS=1 -e PHP_UPLOAD_MAX_FILESIZE=25M -e PHP_POST_MAX_SIZE=50M bunkerity/bunkerized-php
```

For security reasons, file uploads are disabled by default. Here are the explanations of the environment variables :
- `PHP_FILE_UPLOADS` : enable (*1*) or disable (*0*) file uploads (default : *0*)
- `PHP_UPLOAD_MAX_FILESIZE` : maximum size of an uploaded file (default : *10M*)
- `PHP_POST_MAX_SIZE` : maximum size of the whole POST data (default : *10M*)

## Install additional extensions

You can easily add extensions using the following environment variables :
- `APK_ADD` : add additional alpine packages (*apk add*)
- `PECL_INSTALL` : add additional PECL extensions (*pecl install*)
- `PHP_EXT_ENABLE` : enable previously added PECL extensions (*docker-php-ext-enable*)
- `PHP_EXT_INSTALL` : install PHP core extensions (*docker-php-ext-install*)

Simple example to add MySQL extensions :

```
docker run --network mynet -v /path/to/web/files:/www -e PHP_EXT_INSTALL="mysqli pdo pdo_mysql" bunkerity/bunkerized-php
```

Another example to add imagick extension :

```
docker run --network mynet -v /path/to/web/files:/www -e APK_ADD="autoconf gcc musl-dev make imagemagick-dev" -e PECL_INSTALL=imagick -e PHP_EXT_ENABLE=imagick bunkerity/bunkerized-php
```

# Environment variables

## PHP

### Security

`PHP_OPEN_BASEDIR`  
Values : \<*any valid paths inside the container separated with :*\>  
Default value : */www/:/tmp/uploads/:/tmp/sessions/*  
php.ini directive : [open_basedir](https://www.php.net/manual/en/ini.core.php#ini.open-basedir)  
List of paths where PHP is allowed to read and write data.

`PHP_DISABLE_FUNCTIONS`  
Values : \<*list of PHP functions separated with ,*\>  
Default value : *system, exec, shell_exec, passthru, phpinfo, show_source, highlight_file, popen, proc_open, fopen_with_path, dbmopen, dbase_open, putenv, filepro, filepro_rowcount, filepro_retrieve, posix_mkfifo*  
php.ini directive : [disable_functions](https://www.php.net/manual/en/ini.core.php#ini.disable-functions)  
List of disabled functions that PHP can't use anywhere in the code.

`PHP_ALLOW_URL_FOPEN`  
Values : *0* | *1*  
Default value : *0*  
php.ini directive : [allow_url_fopen](https://www.php.net/manual/en/filesystem.configuration.php#ini.allow-url-fopen)  
When set to *0*, disable wrappers like http://, ftp:// or php:// when opening file.

`PHP_ALLOW_URL_INCLUDE`  
Values : *0* | *1*  
Default value : *0*  
php.ini directive : [allow_url_include](https://www.php.net/manual/en/filesystem.configuration.php#ini.allow-url-include)  
When set to *0*, disable wrappers like http://, ftp:// or php:// when using include(), include_once(), require() and require_once().

### Information leak

`PHP_EXPOSE` 
Values : *0* | *1*  
Default value : *0*  
php.ini directive : [expose_php](https://www.php.net/manual/en/ini.core.php#ini.expose-php)  
When set to *0*, avoid sending the X-Powered-By head that includes the PHP version number.

`PHP_DISPLAY_ERRORS`  
Values : *0* | *1*  
Default value : *0*  
php.ini directive : [display_errors](https://www.php.net/manual/en/errorfunc.configuration.php#ini.display-errors)  
When set to *0*, avoid printing PHP errors to the user.

### Misc

`PHP_MEMORY_LIMIT`  
Values : *xK* | *xM* | *xG*  
Default value : *128M*  
php.ini directive : [memory_limit](https://www.php.net/manual/en/ini.core.php#ini.memory-limit)  
The maximum amount of a memory a single script can use.

`PHP_DOC_ROOT`  
Values : \<*any valid path inside the container*\>  
Default value : */www*  
php.ini directive : [doc_root](https://www.php.net/manual/en/ini.core.php#ini.doc-root)  
The root directory use by PHP to get the files. Don't change it unless you want to build your own image.

## Data uploads

### Files

`PHP_FILE_UPLOADS`  
Values : *0* | *1*  
Default value : *0*  
php.ini directive : [file_uploads](https://www.php.net/manual/en/ini.core.php#ini.file-uploads)  
When set to *0*, users are not allowed to upload files.

`PHP_UPLOAD_MAX_FILESIZE`  
Values : *xK* | *xM* | *xG*  
Default value : *10M*  
php.ini directive : [upload_max_filesize](https://www.php.net/manual/en/ini.core.php#ini.upload-max-filesize)  
The maximum size of a single file that can be sent by users when `PHP_FILE_UPLOADS` is set to *1*.

`PHP_UPLOAD_TMP_DIR`  
Values : \<*any valid path inside the container*\>  
Default value : */tmp/uploads*  
php.ini directive : [upload_tmp_dir](https://www.php.net/manual/en/ini.core.php#ini.upload-tmp-dir)  
Where PHP will save files when they are uploaded. This path must be set in the `PHP_OPEN_BASEDIR` environment variable.

### POST

`PHP_POST_MAX_SIZE`  
Values : *xK* | *xM* | *xG*  
Default value : *10M*  
php.ini directive : [post_max_size](https://www.php.net/manual/en/ini.core.php#ini.post-max-size)  
The maximum size that can be sent by users through a POST request.

## Sessions

`PHP_SESSION_NAME`  
Values : *random* | \<*any string*\>  
Default value : *random*  
php.ini directive : [session.name](https://www.php.net/manual/en/session.configuration.php#ini.session.name)  
Name of the cookie sent to the users when PHP uses sessions. Special value *random* will generate a random one.

`PHP_SESSION_SECURE`  
Values : *0* | *1*  
Default value : *0*  
php.ini directive : [session.cookie_secure](https://www.php.net/manual/en/session.configuration.php#ini.session.cookie-secure)  
When set to *1*, the "Secure" flag will be set to the session cookie and clients will only send this cookie through https.

`PHP_SESSION_HTTPONLY`  
Values : *0* | *1*  
Default value : *1*  
php.ini directive : [session.cookie_httponly](https://www.php.net/manual/en/session.configuration.php#ini.session.cookie-httponly)  
When set to *1*, the "HttpOnly" flag will be set to the session cookie and JavaScript won't be allowed to access it.

`PHP_SESSION_PATH`  
Values : \<*any valid URI*\>  
Default value : */*  
php.ini directive : [session.cookie_path](https://www.php.net/manual/en/session.configuration.php#ini.session.cookie-path)  
Clients will only send the session cookie the URI is inside this path.

`PHP_SESSION_SAMESITE`  
Values : *Lax* | *Strict*  
Default value : *Strict*  
php.ini directive : [session.cookie_samesite](https://www.php.net/manual/en/session.configuration.php#ini.session.cookie-samesite)  
When set to *Lax*, session cookie will only be sent from cross-site POST requests. When set to *Strict*, session cookie will never be sent from cross-site requests.

`PHP_SESSION_SAVE_PATH`  
Values : \<*any valid path inside the container*\>  
Default value : */tmp/sessions*  
php.ini directive : [session.save_path](https://www.php.net/manual/en/session.configuration.php#ini.session.save-path)  
The directory where PHP will save sessions data inside the container. This directory must be present in the `PHP_OPEN_BASEDIR` environment variable.

## Snuffleupagus

`USE_SNUFFLEUPAGUS`  
Values : *yes* | *no*    
Default value : *yes*  
When set to *yes*, the [Snuffleupagus](https://snuffleupagus.readthedocs.io/) module will be enabled with a [default configuration](https://github.com/bunkerity/bunkerized-php/blob/master/confs/snuffleupagus.rules). See [here](#Snuffleupagus-2) if you want to use your own configuration.

## Logging

`LOGROTATE_MINSIZE`  
Values : *x* | *xk* | *xM* | *xG*  
Default value : 10M  
The minimum size of a log file before being rotated (no letter = bytes, k = kilobytes, M = megabytes, G = gigabytes).

`LOGROTATE_MAXAGE`  
Values : *\<any integer\>*  
Default value : 7  
The number of days before rotated files are deleted.

## Additional modules

# Custom configurations

## php-fpm

## php.ini

## Snuffleupagus

