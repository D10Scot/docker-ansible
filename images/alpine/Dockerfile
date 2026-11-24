# syntax=docker/dockerfile:1.29.0@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183
ARG FLAVOR=full

FROM alpine:3.24@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf AS builder
ARG FLAVOR
ARG TARGETARCH
ENV PATH=/opt/ansible/bin:$PATH VIRTUAL_ENV=/opt/ansible
RUN apk add --no-cache python3 py3-pip build-base python3-dev libffi-dev openssl-dev cargo rust
RUN python3 -m venv /opt/ansible
COPY requirements/ /tmp/requirements/
RUN /opt/ansible/bin/pip install --no-cache-dir --require-hashes \
      -r "/tmp/requirements/alpine-${FLAVOR}-${TARGETARCH}.txt"

FROM alpine:3.24@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf AS runtime
ARG FLAVOR
RUN apk upgrade --no-cache \
 && apk add --no-cache python3 openssh-client sshpass git rsync ca-certificates \
 && addgroup -g 1000 ansible \
 && adduser -u 1000 -G ansible -D -h /home/ansible ansible
COPY --from=builder /opt/ansible /opt/ansible
ENV PATH=/opt/ansible/bin:$PATH VIRTUAL_ENV=/opt/ansible \
    ANSIBLE_FORCE_COLOR=1 PYTHONUNBUFFERED=1
USER ansible
WORKDIR /ansible
LABEL org.opencontainers.image.source="https://github.com/D10Scot/docker-ansible" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.title="ansible (${FLAVOR}, alpine)"
CMD ["ansible", "--version"]
