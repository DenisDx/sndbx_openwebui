# syntax=docker/dockerfile:1.7

# Open WebUI VM image for sndbx.
# Based on the official Open WebUI image; this layer adds the sndbx runtime
# contract: a dedicated unprivileged account that can be remapped to the host
# user, key-only SSH, and a lifecycle hook. All persistent state lives in the
# bind-mounted /app/backend/data directory.

ARG OPENWEBUI_IMAGE=ghcr.io/open-webui/open-webui:main
FROM ${OPENWEBUI_IMAGE}

USER root

ARG WEBUI_UID=1000
ARG WEBUI_GID=1000

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        acl \
        attr \
        ca-certificates \
        gosu \
        less \
        locales \
        nano \
        openssh-client \
        openssh-server \
        openssl \
        procps \
        rsync \
        tini \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && groupadd --gid "${WEBUI_GID}" openwebui \
    && useradd \
        --uid "${WEBUI_UID}" \
        --gid "${WEBUI_GID}" \
        --home-dir /app/backend/data \
        --shell /bin/bash \
        --no-create-home \
        openwebui \
    && usermod --append --groups root openwebui \
    && mkdir --parents /app/backend/data/config \
    && printf '%s\n' \
        'PermitRootLogin no' \
        'PasswordAuthentication no' \
        'KbdInteractiveAuthentication no' \
        'UsePAM no' \
        'AllowUsers openwebui' \
        > /etc/ssh/sshd_config.d/openwebui.conf \
    && rm -rf /var/lib/apt/lists/*

COPY docker/entrypoint.sh /usr/local/bin/open-webui-entrypoint
COPY docker/start-open-webui.sh /usr/local/bin/open-webui-start
COPY docker/load-open-webui-env.sh /usr/local/lib/open-webui/load-env.sh
RUN chmod 0755 /usr/local/bin/open-webui-entrypoint /usr/local/bin/open-webui-start \
    && chmod 0644 /usr/local/lib/open-webui/load-env.sh \
    && printf '%s\n' \
        'if [[ -r /usr/local/lib/open-webui/load-env.sh ]]; then' \
        '    source /usr/local/lib/open-webui/load-env.sh' \
        'fi' \
        >> /etc/bash.bashrc \
    && printf '%s\n' \
        'source /usr/local/lib/open-webui/load-env.sh' \
        > /etc/profile.d/open-webui-env.sh \
    && chmod 0644 /etc/profile.d/open-webui-env.sh

# Lifecycle hook executed by sndbx after the container starts.
COPY app.py /opt/sndbx-image/app.py
RUN chmod 0755 /opt/sndbx-image/app.py

# Persistent home for caches and the mounted data directory.
ENV HOME=/app/backend/data
WORKDIR /app/backend

EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/open-webui-entrypoint"]
CMD ["/usr/local/bin/open-webui-start"]
