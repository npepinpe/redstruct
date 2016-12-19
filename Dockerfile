# Base image; alpine variant uses Linux Alpine, which creates very small images
FROM ruby:2.3.3-alpine

# Install packages
RUN apk add --update build-base libffi-dev
RUN gem install bundler

# Always run from the app dir
WORKDIR /var/lib/redstruct

# Copy over the application
COPY lib/redstruct/version.rb lib/redstruct/version.rb
COPY redstruct.gemspec redstruct.gemspec
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock

# Install app dependencies
RUN bundle install
