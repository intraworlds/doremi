FROM ruby:2.4.1-alpine
RUN mkdir /doremi
WORKDIR /doremi
ADD Gemfile /doremi/Gemfile
ADD Gemfile.lock /doremi/Gemfile.lock
RUN set -x && \
    gem install bundler && \
    bundle install
