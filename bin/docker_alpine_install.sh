#!/bin/sh

apk --no-cache add tzdata
apk --no-cache add --virtual .build-dependencies build-base ruby-dev mariadb-dev postgresql14-dev sqlite-dev
bundle config set --local without 'development test'
bundle install
apk del .build-dependencies
apk --no-cache add mariadb-connector-c sqlite-libs libpq
