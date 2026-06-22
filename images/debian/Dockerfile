# syntax=docker/dockerfile:1
ARG FLAVOR=full

FROM debian:13@sha256:fe7312b5f05bf5f43fad76bcd8945642e4e47a68aefd1b73f447615899d0fac1 AS builder
ARG FLAVOR
ARG TARGETARCH
ENV PATH=/opt/ansible/bin:$PATH VIRTUAL_ENV=/opt/ansible DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      python3 python3-venv python3-dev gcc libffi-dev libssl-dev cargo rustc \
 && rm -rf /var/lib/apt/lists/*
RUN python3 -m venv /opt/ansible && /opt/ansible/bin/pip install --no-cache-dir --upgrade pip
COPY requirements/ /tmp/requirements/
RUN /opt/ansible/bin/pip install --no-cache-dir --require-hashes \
      -r "/tmp/requirements/debian-${FLAVOR}-${TARGETARCH}.txt"

FROM debian:13@sha256:fe7312b5f05bf5f43fad76bcd8945642e4e47a68aefd1b73f447615899d0fac1 AS runtime
ARG FLAVOR
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends \
      python3 openssh-client sshpass git rsync ca-certificates \
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
      org.opencontainers.image.title="ansible (${FLAVOR}, debian)"
CMD ["ansible", "--version"]
