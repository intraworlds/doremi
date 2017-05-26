FROM ruby:2.4.1-alpine
RUN mkdir /doremi
WORKDIR /doremi
COPY Gemfile Gemfile.lock ./
RUN set -x && \
    gem install bundler && \
    bundle install
