FROM alpine:3.7@sha256:ccba511b1d6b5f1d83825a94f9d5b05528db456d9cf14a1ea1db892c939cda64

MAINTAINER Yash Singh <yash.2007.1993@gmail.com>

RUN apk add --no-cache curl mongodb-tools py2-pip && \
  pip install pymongo awscli && \
  mkdir /backup

ENV S3_PATH=mongodb AWS_DEFAULT_REGION=us-east-1

COPY entrypoint.sh /usr/local/bin/entrypoint
COPY backup.sh /usr/local/bin/backup
COPY mongouri.py /usr/local/bin/mongouri

VOLUME /backup

CMD /usr/local/bin/entrypoint
