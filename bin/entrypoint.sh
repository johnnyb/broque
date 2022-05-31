#!/bin/sh

MODE=$1

# Set Rails environment
export RAILS_ENV=production

# Check special run modes
if [ "$MODE" = "shell" ]; then
	exec /bin/bash
fi
if [ "$MODE" = "operator" ]; then
	exec bundle exec rails runner Kubernetes::Operator.run
fi

# Wait for port to open (assuming it is a network connection)
CHECK_HOST=${DB_HOST:-localhost}
CHECK_PORT=${DB_PORT:-5432}
while ! nc -z $CHECK_HOST $CHECK_PORT ; do sleep 1 ; done

# only run service if the migration is successful
bundle exec rake db:migrate && exec bundle exec rails server
