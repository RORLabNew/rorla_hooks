
# How to run

## Development

```
$ bundle exec ruby server.rb
```

## Production

```
$ docker run -d -p 8443:8443 -v /var/run/docker.sock:/var/run/docker.sock -v /root/.ssl/server.crt:/app/server.crt -v /root/.ssl/server.key:/app/server.key -e SECRET_KEY_BASE=xxx -e MANDRILL_USERNAME=xxx -e MANDRILL_APIKEY=xxx -e RORLA_HOST=xxx -e RORLA_LOGENTRIES_TOKEN=xxx -e API_TOKEN=xxx rorla/rorla-hooks
```

# Docker 

## Build & Push

자동으로 Docker hub 에서 진행된다. github에 푸쉬만 하면됨.