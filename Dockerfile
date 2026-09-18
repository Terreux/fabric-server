FROM eclipse-temurin:25-jre-noble

ARG MC_VERSION=26.3
ARG FABRIC_LOADER_VERSION=0.19.5
ARG FABRIC_LAUNCHER_VERSION=1.1.2
ARG MC_UID=10001
ARG MC_GID=10001

LABEL org.opencontainers.image.title="Fabric Minecraft Server" \
      org.opencontainers.image.description="Minimal Fabric Minecraft server with persistent external data" \
      org.opencontainers.image.source="https://github.com/terreux/fabric-server" \
      org.opencontainers.image.version="${MC_VERSION}" \
      io.terreux.minecraft.version="${MC_VERSION}" \
      io.terreux.fabric.loader.version="${FABRIC_LOADER_VERSION}" \
      io.terreux.fabric.launcher.version="${FABRIC_LAUNCHER_VERSION}"

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        ca-certificates \
        curl \
        netcat-openbsd \
        tini \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid "${MC_GID}" minecraft \
    && useradd \
        --uid "${MC_UID}" \
        --gid "${MC_GID}" \
        --home-dir /data \
        --create-home \
        --shell /usr/sbin/nologin \
        minecraft

WORKDIR /opt/fabric

RUN curl \
        --fail \
        --show-error \
        --location \
        --output fabric-server-launch.jar \
        "https://meta.fabricmc.net/v2/versions/loader/${MC_VERSION}/${FABRIC_LOADER_VERSION}/${FABRIC_LAUNCHER_VERSION}/server/jar" \
    && test -s fabric-server-launch.jar \
    && chown minecraft:minecraft fabric-server-launch.jar

COPY --chown=minecraft:minecraft \
    entrypoint.sh \
    /usr/local/bin/entrypoint.sh

RUN chmod 0755 /usr/local/bin/entrypoint.sh \
    && mkdir -p /data \
    && chown minecraft:minecraft /data

ENV EULA=false \
    MEMORY_MIN=1G \
    MEMORY_MAX=4G \
    JAVA_FLAGS=""

WORKDIR /data

EXPOSE 25565/tcp

HEALTHCHECK \
    --interval=30s \
    --timeout=5s \
    --start-period=120s \
    --retries=5 \
    CMD nc -z 127.0.0.1 25565 || exit 1

STOPSIGNAL SIGTERM

USER minecraft

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]