#!/bin/bash

docker pull rorla/rorla:latest
docker stop rorla-latest
docker rm rorla-latest

# DB Migrate
docker run \
  --link mysql:mysql \
  --volumes-from rorla_uploads \
  -e SECRET_KEY_BASE=$SECRET_KEY_BASE \
  -e MANDRILL_USERNAME=$MANDRILL_USERNAME \
  -e MANDRILL_APIKEY=$MANDRILL_APIKEY \
  -e RORLA_HOST=$RORLA_HOST \
  -e RORLA_LOGENTRIES_TOKEN=$RORLA_LOGENTRIES_TOKEN \
  -it --rm \
  rorla/rorla:latest bin/rake db:migrate

# start
docker run --name rorla-latest \
  --link mysql:mysql \
  --volumes-from rorla_uploads \
  -e SECRET_KEY_BASE=$SECRET_KEY_BASE \
  -e MANDRILL_USERNAME=$MANDRILL_USERNAME \
  -e MANDRILL_APIKEY=$MANDRILL_APIKEY \
  -e RORLA_HOST=$RORLA_HOST \
  -e RORLA_LOGENTRIES_TOKEN=$RORLA_LOGENTRIES_TOKEN \
  -p 80:80 -d \
  rorla/rorla:latest
