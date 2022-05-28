FROM ruby:3

# For debugging
RUN apt update; apt install -y vim

WORKDIR /app

COPY . .

RUN bundle install

ENTRYPOINT ["/app/bin/entrypoint.sh"]
