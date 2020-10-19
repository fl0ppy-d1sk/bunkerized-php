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

## File uploads

## Sessions

## Snuffleupagus

## Logging

# Custom configurations

## php-fpm

## php.ini

## Snuffleupagus

