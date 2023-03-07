# https://developer.hashicorp.com/terraform/cli/config/config-file#implied-local-mirror-directories
# export TF_PLUGIN_CACHE_DIR=/plugin-cache
FROM hashicorp/terraform:1.3.6 AS builder
WORKDIR /build
COPY . /build
RUN terraform init
RUN cp -r .terraform/providers /plugin-cache

FROM busybox:latest
COPY --from=builder /plugin-cache /plugin-cache
