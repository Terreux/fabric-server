# Fabric Minecraft Server

A lightweight Docker image for running a Fabric Minecraft server with persistent external data.

The image is built on the official Eclipse Temurin Java runtime and keeps worlds, mods, configuration, logs, and player data outside the container under `/data`.

No modpacks or third-party mods are included.

## Features

* Fabric Minecraft server
* Eclipse Temurin Java runtime
* Runs as a non-root user
* Persistent `/data` storage
* Configurable Java memory
* Optional additional JVM flags
* Built-in health check
* Graceful shutdown handling
* No bundled mods or modpacks

## Repository Structure

```text
fabric-server/
├── Dockerfile
├── compose.yaml
├── entrypoint.sh
├── .env.example
├── .gitignore
└── README.md
```

Runtime data is created separately:

```text
data/
├── world/
├── mods/
├── config/
├── logs/
├── server.properties
├── ops.json
├── whitelist.json
└── eula.txt
```

The `data/` directory is intentionally excluded from Git.

## Requirements

* Docker Engine
* Docker Compose
* At least 2 GB of available memory
* Minecraft Java Edition

More memory may be required when running several mods or supporting many players.

## Quick Start with Docker Compose

Clone the repository:

```bash
git clone https://github.com/terreux/fabric-server.git
cd fabric-server
```

Create the environment file:

```bash
cp .env.example .env
```

Edit `.env` and accept the Minecraft EULA:

```dotenv
EULA=true
```

Create the persistent data directory:

```bash
mkdir -p data
sudo chown -R 10001:10001 data
```

Build and start the server:

```bash
docker compose up --build -d
```

Follow the startup logs:

```bash
docker compose logs -f
```

When startup is complete, Minecraft should report a message similar to:

```text
Done! For help, type "help"
```

Connect locally using:

```text
localhost:25565
```

For a remote server, connect using the host IP address or DNS name.

## Using the Published Docker Image

Pull the image:

```bash
docker pull terreux/fabric-server:latest
```

Run the server:

```bash
mkdir -p data
sudo chown -R 10001:10001 data

docker run -d \
  --name fabric-server \
  --restart unless-stopped \
  -p 25565:25565 \
  -e EULA=true \
  -e MEMORY_MIN=1G \
  -e MEMORY_MAX=4G \
  -v "$(pwd)/data:/data" \
  terreux/fabric-server:latest
```

View the logs:

```bash
docker logs -f fabric-server
```

Stop the container:

```bash
docker stop fabric-server
```

Remove the container:

```bash
docker rm fabric-server
```

Persistent server data remains in the local `data/` directory.

## Docker Compose Configuration

The included `compose.yaml` uses the following structure:

```yaml
services:
  fabric-server:
    image: terreux/fabric-server:latest
    build:
      context: .
      dockerfile: Dockerfile

    container_name: fabric-server
    restart: unless-stopped

    environment:
      EULA: "${EULA:-false}"
      MEMORY_MIN: "${MEMORY_MIN:-1G}"
      MEMORY_MAX: "${MEMORY_MAX:-4G}"
      JAVA_FLAGS: "${JAVA_FLAGS:-}"

    ports:
      - "${SERVER_PORT:-25565}:25565"

    volumes:
      - ./data:/data

    stdin_open: true
    tty: true

    stop_grace_period: 60s
```

## Environment Variables

| Variable      | Default | Description                                        |
| ------------- | ------: | -------------------------------------------------- |
| `EULA`        | `false` | Must be set to `true` before the server will start |
| `MEMORY_MIN`  |    `1G` | Initial Java heap allocation                       |
| `MEMORY_MAX`  |    `4G` | Maximum Java heap allocation                       |
| `JAVA_FLAGS`  |   Empty | Additional JVM arguments                           |
| `SERVER_PORT` | `25565` | Host port mapped to Minecraft                      |

Example `.env`:

```dotenv
EULA=true

MEMORY_MIN=2G
MEMORY_MAX=6G

JAVA_FLAGS=

SERVER_PORT=25565
```

Setting `EULA=true` confirms that you have reviewed and accepted the Minecraft End User License Agreement.

## Persistent Data

The server stores all runtime data under:

```text
/data
```

The Compose configuration maps this to:

```text
./data
```

This includes:

* Worlds
* Mods
* Configuration
* Logs
* Player data
* Whitelist and ban files
* Server properties

The container image can be rebuilt, upgraded, or replaced without deleting this data.

## Adding Mods

Stop the server before changing mods:

```bash
docker compose down
```

Place compatible Fabric mod JAR files in:

```text
data/mods/
```

Start the server again:

```bash
docker compose up -d
docker compose logs -f
```

Many Fabric mods require Fabric API or additional dependencies.

Some mods must also be installed on every player’s Minecraft client.

This image does not automatically download, update, or remove mods.

## Importing an Existing World

Stop the server:

```bash
docker compose down
```

Back up the current world:

```bash
mv data/world data/world-backup
```

Copy the existing world:

```bash
cp -a /path/to/existing-world data/world
sudo chown -R 10001:10001 data/world
```

The imported world should contain `level.dat` directly:

```text
data/world/level.dat
```

Avoid an extra nested directory such as:

```text
data/world/existing-world/level.dat
```

Confirm that `data/server.properties` contains:

```properties
level-name=world
```

Start the server:

```bash
docker compose up -d
docker compose logs -f
```

Always preserve a backup before opening an existing world.

Minecraft may upgrade the world format during startup.

## File Permissions

The container runs as a non-root user:

```text
UID 10001
GID 10001
```

When using a Linux bind mount, give the container ownership of the data directory:

```bash
sudo chown -R 10001:10001 data
```

Check numeric ownership:

```bash
ls -ln data
```

## Server Configuration

After the first successful startup, edit:

```text
data/server.properties
```

Common options include:

```properties
motd=A Fabric Minecraft Server
difficulty=normal
gamemode=survival
max-players=20
online-mode=true
white-list=false
view-distance=10
simulation-distance=10
```

Restart after editing:

```bash
docker compose restart
```

## Common Commands

Start the server:

```bash
docker compose up -d
```

Build and start:

```bash
docker compose up --build -d
```

View logs:

```bash
docker compose logs -f
```

Check status:

```bash
docker compose ps
```

Restart:

```bash
docker compose restart
```

Stop and remove the container:

```bash
docker compose down
```

Rebuild without using cached layers:

```bash
docker compose build --no-cache
docker compose up -d
```

## Health Check

The image checks whether the Minecraft server is listening on TCP port `25565`.

Check the status:

```bash
docker inspect fabric-server \
  --format '{{.State.Health.Status}}'
```

Possible results include:

```text
starting
healthy
unhealthy
```

## Backups

Stop the server before creating a basic backup:

```bash
docker compose down
```

Create an archive:

```bash
mkdir -p backups

tar -czf \
  backups/fabric-server-$(date +%Y%m%d-%H%M%S).tar.gz \
  data
```

Start the server again:

```bash
docker compose up -d
```

For production servers, use a backup process that safely flushes Minecraft world data before copying files.

## Updating

Pull the latest published image:

```bash
docker compose pull
```

Recreate the container:

```bash
docker compose up -d
```

The mounted `/data` directory remains unchanged.

Back up server data before changing Minecraft, Fabric, Java, or mod versions.

## Building the Image

Build the image locally:

```bash
docker build \
  -t terreux/fabric-server:26.2 \
  -t terreux/fabric-server:latest \
  .
```

Run the locally built image:

```bash
docker compose up -d
```

Push the image to Docker Hub:

```bash
docker login

docker push terreux/fabric-server:26.2
docker push terreux/fabric-server:latest
```

## Image Design

The container image contains:

```text
Java runtime
Fabric launcher
Startup script
Health check
```

The persistent `/data` directory contains:

```text
Worlds
Mods
Configuration
Logs
Player and server data
```

This keeps the server runtime reproducible while leaving user-created content outside the image.

## Networking

The Minecraft server listens on:

```text
25565/tcp
```

The default Compose mapping is:

```text
25565:25565
```

To publish a different host port:

```yaml
ports:
  - "25566:25565"
```

Players would then connect using:

```text
server-address:25566
```

VPN software may block or reroute local connections. Make sure local network access is enabled when testing through a VPN.

Do not expose Minecraft RCON directly to the public internet.

## Project Links

Docker Hub:

```text
https://hub.docker.com/r/terreux/fabric-server
```

GitHub:

```text
https://github.com/terreux/fabric-server
```

Fabric:

```text
https://fabricmc.net/
```

## Disclaimer

This is an independent community container image.

It is not affiliated with or endorsed by Mojang Studios, Microsoft, FabricMC, Eclipse Adoptium, or Docker.

Minecraft is a trademark of Microsoft Corporation.

Review the licenses and distribution requirements of any mods added to the server.
