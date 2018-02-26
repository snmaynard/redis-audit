FROM ruby:alpine

COPY . /redis-audit

RUN set -ex; \
    apk --no-cache add build-base; \
    cd redis-audit; \
    bundle install; \
    apk del build-base;

WORKDIR "/redis-audit"

ENTRYPOINT ["ruby", "redis-audit.rb"]