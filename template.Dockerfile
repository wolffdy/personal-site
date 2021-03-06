# For now, will maintain two Dockerfiles for different architectures, though I
# should eventually write a template so they can be generated from a single
# source

# Using multistage build for a clean, repeatable build environment
# Don't need to have this be ARM because we are building JS
FROM node:alpine AS builder
RUN apk update
RUN npm install @ampproject/toolbox-cli -g

COPY static/index.html ./
RUN mkdir -p ./assets
COPY static/assets ./assets

# RUN amp optimize index.html > index.html

# -------------------------------------------------------------------------

FROM {NGINX}:latest

# Need QEMU to build ARM on x86_64 laptop
# Theoretically, for production, this could be removed to trim the image size
COPY docker/qemu-{QEMU-ARCH}-static /usr/bin

RUN apt-get update

ENV WORKDIR /usr/share/nginx/html
RUN mkdir -p $WORKDIR

WORKDIR $WORKDIR

COPY --from=builder index.html .
COPY --from=builder assets ./assets
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx/personal-site-insecure.conf /etc/nginx/conf.d/personal-site.conf

WORKDIR /opt
COPY docker/entrypoint.sh .
CMD ./entrypoint.sh
