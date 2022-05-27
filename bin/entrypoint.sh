#!/bin/sh

MODE=$1

# Set Rails environment
export RAILS_ENV=production

# Check special run modes
if [ "$MODE" = "shell" ]; then
  exec /bin/bash
fi

bundle exec rake db:migrate
exec bundle exec rails server
