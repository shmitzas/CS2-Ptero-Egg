# Dockerfile with SteamRT3
FROM        registry.gitlab.steamos.cloud/steamrt/sniper/platform:latest-container-runtime-depot
LABEL       maintainer="paslaugos.rampage@gmail.com" \
            org.opencontainers.image.description="SteamRT3 Counter-Strike 2 server image for Pterodactyl and Pelican." \
            org.opencontainers.image.source="https://github.com/shmitzas/CS2-Ptero-Egg"

# Prep OS
RUN         mkdir -p /etc/sudoers.d && \
            echo "%sudo ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/flatdeb && \
            chmod 0440 /etc/sudoers.d/flatdeb

ENV         DEBIAN_FRONTEND=noninteractive
# Debian 11 is EOL: deb.debian.org still indexes bullseye-security but 404s its .debs
RUN         sed -i '/deb\.debian\.org\/debian-security/d' /etc/apt/sources.list && \
            apt update && \
            apt install -y iproute2 jq unzip rsync curl && \
            apt-get clean

# Create directories and copy files
RUN         mkdir -p /scripts /utils
COPY        ./scripts /scripts/
COPY        ./utils /utils/
COPY        ./entrypoint.sh /entrypoint.sh

# Set permissions (read-only + executable)
RUN         chmod 555 /scripts/*.sh && \
            chmod 555 /scripts/updaters/*.sh && \
            chmod 555 /utils/*.sh && \
            chmod 555 /entrypoint.sh

USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

CMD         [ "/bin/bash", "/entrypoint.sh" ]
