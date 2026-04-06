FROM ruby:4

# For startup script
RUN apt update; apt install -y netcat-traditional

# For debugging
RUN apt install -y vim postgresql-client 


WORKDIR /app

COPY . .

RUN bundle install

ENTRYPOINT ["/app/bin/entrypoint.sh"]
