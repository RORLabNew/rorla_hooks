FROM seapy/ruby:2.1.2
MAINTAINER ChangHoon Jeong <iamseapy@gmail.com>

WORKDIR /app

#(required) Install App
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN bundle install --without development test
ADD . /app

EXPOSE 8443

CMD bundle exec ruby server.rb