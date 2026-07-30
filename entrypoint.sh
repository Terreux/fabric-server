#!/usr/bin/env bash

set -Eeuo pipefail

readonly SERVER_JAR="/opt/fabric/fabric-server-launch.jar"
readonly DATA_DIR="/data"

log() {
    printf '[fabric-server] %s\n' "$*"
}

fail() {
    log "ERROR: $*"
    exit 1
}

if [[ "${EULA,,}" != "true" ]]; then
    fail "Set EULA=true after reviewing the Minecraft EULA."
fi

[[ -f "${SERVER_JAR}" ]] || fail "Fabric launcher is missing."
[[ -n "${MEMORY_MIN:-}" ]] || fail "MEMORY_MIN cannot be empty."
[[ -n "${MEMORY_MAX:-}" ]] || fail "MEMORY_MAX cannot be empty."

mkdir -p \
    "${DATA_DIR}/mods" \
    "${DATA_DIR}/config"

printf 'eula=true\n' > "${DATA_DIR}/eula.txt"

log "Starting Fabric Minecraft server"
log "Data directory: ${DATA_DIR}"
log "Memory: ${MEMORY_MIN}–${MEMORY_MAX}"
log "Java: $(java -version 2>&1 | head -n 1)"

java_command=(
    java
    "-Xms${MEMORY_MIN}"
    "-Xmx${MEMORY_MAX}"
)

if [[ -n "${JAVA_FLAGS:-}" ]]; then
    # Intentional splitting of multiple JVM flags.
    # shellcheck disable=SC2206
    extra_java_flags=( ${JAVA_FLAGS} )
    java_command+=("${extra_java_flags[@]}")
fi

java_command+=(
    -jar
    "${SERVER_JAR}"
    nogui
)

exec "${java_command[@]}"