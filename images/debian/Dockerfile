# syntax=docker/dockerfile:1
ARG FLAVOR=full

FROM debian:12@sha256:49ba348354a28e39c70beffd6cf43bdb8d55d81ce4b746b0428717d054b8bbc4 AS builder
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

FROM debian:12@sha256:49ba348354a28e39c70beffd6cf43bdb8d55d81ce4b746b0428717d054b8bbc4 AS runtime
ARG FLAVOR
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
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
