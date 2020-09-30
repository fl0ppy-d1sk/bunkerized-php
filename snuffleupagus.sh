#!/bin/sh

# install deps
apk add --no-cache --virtual build git make php7-dev gcc musl-dev pcre-dev

# install snuffleupagus
cd /tmp
git clone https://github.com/jvoisin/snuffleupagus.git
cd snuffleupagus
make -j install

# remove deps and temp files
cd /tmp
rm -rf /tmp/snuffleupagus
apk del build

