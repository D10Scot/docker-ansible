# syntax=docker/dockerfile:1.29.0@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183
ARG FLAVOR=full

FROM ubuntu:26.04@sha256:d66b366dac61b575bee2aef07e9c26e8070096fbe84a3d4d3eb0da069b5d76db AS builder
ARG FLAVOR
ARG TARGETARCH
ENV PATH=/opt/ansible/bin:$PATH VIRTUAL_ENV=/opt/ansible DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      python3 python3-venv python3-dev gcc libffi-dev libssl-dev cargo rustc \
 && rm -rf /var/lib/apt/lists/*
RUN python3 -m venv /opt/ansible
COPY requirements/ /tmp/requirements/
RUN /opt/ansible/bin/pip install --no-cache-dir --require-hashes \
      -r "/tmp/requirements/ubuntu-${FLAVOR}-${TARGETARCH}.txt"

FROM ubuntu:26.04@sha256:d66b366dac61b575bee2aef07e9c26e8070096fbe84a3d4d3eb0da069b5d76db AS runtime
ARG FLAVOR
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends \
      python3 openssh-client sshpass git rsync ca-certificates \
 && userdel -r ubuntu \
 && groupadd -g 1000 ansible \
 && useradd -u 1000 -g 1000 -m -d /home/ansible ansible \
 && rm -rf /var/lib/apt/lists/*
COPY --from=builder /opt/ansible /opt/ansible
ENV PATH=/opt/ansible/bin:$PATH VIRTUAL_ENV=/opt/ansible \
    ANSIBLE_FORCE_COLOR=1 PYTHONUNBUFFERED=1
USER ansible
WORKDIR /ansible
LABEL org.opencontainers.image.source="https://github.com/D10Scot/docker-ansible" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.title="ansible (${FLAVOR}, ubuntu)"
CMD ["ansible", "--version"]
