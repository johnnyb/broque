FROM ruby:3

WORKDIR /app

COPY . .

RUN bundle install

ENTRYPOINT ["/app/bin/entrypoint.sh"]
