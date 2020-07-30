FROM docker:stable

LABEL "name"="Docker Autograde"

RUN apk update \
  && apk upgrade \
  && apk add --no-cache git bash curl docker-compose jq

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
