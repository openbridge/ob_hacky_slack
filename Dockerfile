FROM alpine:latest
RUN apk add --update \
          bash \
          curl \
    && rm /var/cache/apk/*
COPY slack.sh /usr/bin/slack
RUN chmod +x /usr/bin/slack \
    && touch /tmp/ip.txt \
    && mkdir -p /tmp
