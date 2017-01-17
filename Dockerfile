FROM alpine:latest
RUN apk add --update \
          bash \
          curl \
    && rm /var/cache/apk/*
COPY slack.sh /usr/bin/slack
RUN chmod +x /slack.sh \
    && touch /tmp/ip.txt \
    && mkdir -p /tmp
