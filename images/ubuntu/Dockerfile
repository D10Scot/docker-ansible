# syntax=docker/dockerfile:1
ARG FLAVOR=full

FROM ubuntu:24.04@sha256:786a8b558f7be160c6c8c4a54f9a57274f3b4fb1491cf65146521ae77ff1dc54 AS builder
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
      -r "/tmp/requirements/ubuntu-${FLAVOR}-${TARGETARCH}.txt"

FROM ubuntu:24.04@sha256:786a8b558f7be160c6c8c4a54f9a57274f3b4fb1491cf65146521ae77ff1dc54 AS runtime
ARG FLAVOR
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
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
