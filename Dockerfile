FROM --platform=linux/amd64 ruby:3-alpine

WORKDIR /app

COPY . .

RUN bin/docker_alpine_install.sh

ENTRYPOINT /app/bin/entrypoint.sh
