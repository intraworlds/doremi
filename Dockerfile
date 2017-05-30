FROM ruby:alpine

RUN mkdir /doremi
WORKDIR /doremi

# install deps
COPY Gemfile Gemfile.lock ./
RUN set -x && \
    gem install bundler && \
    bundle install

# add application
COPY lib ./lib

CMD [ "ruby", "-I", "./lib/", "./lib/doremi.rb", "--run" ]
