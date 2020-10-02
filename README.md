# bunkerized-php

<img src="https://github.com/bunkerity/bunkerized-php/blob/master/logo.png?raw=true" width="425" />

php-fpm Docker image secure by default.

Non-exhaustive list of features :
- Prevent PHP leaks : version, errors, warnings, ...
- Disable dangerous functions : system, exec, shell_exec, ...
- Limit files accessed by PHP via open_basedir
- State-of-the-art session cookie security : HttpOnly, SameSite, ...
- Integrated [Snuffleupagus](https://snuffleupagus.readthedocs.io) security module
- Easy to configure with environment variables

# Table of contents

# Quickstart guide

## Run with default settings

## In combination with bunkerized-nginx

## Install additional extensions

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

