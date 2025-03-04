# SFTP Server Docker Image

A secure, configurable SFTP server in a Docker container for easy file transfers.

## Features

- Chroot environment for SFTP users
- Configurable user ID and group ID
- Support for password and public key authentication
- Persistent SSH host keys
- Modern encryption algorithms
- Terrapin attack protection

## Quick Start

```bash
# Start with password authentication (required)
docker run --name sftp -p 2222:22 -e PASS=your_secure_password -d mobilistics/sftp

# With data volume
docker run --name sftp -p 2222:22 -v /path/on/host:/data/incoming -d mobilistics/sftp

# With persistent SSH keys
docker run --name sftp -p 2222:22 \
  -v /path/on/host/data:/data/incoming \
  -v /path/on/host/ssh:/ssh \
  -d mobilistics/sftp

# With custom user credentials
docker run --name sftp -p 2222:22 \
  -v /path/on/host/data:/data/incoming \
  -e USER=myuser \
  -e PASS=secure_password \
  -d mobilistics/sftp
```

## Configuration Options

| Environment Variable | Description                                 | Default                                  | Example                   |
| -------------------- | ------------------------------------------- | ---------------------------------------- | ------------------------- |
| `USER`               | SFTP username                               | `sftp`                                   | `USER=myuser`             |
| `PASS`               | User's password                             | _No default, required if PUBKEY not set_ | `PASS=my_secure_password` |
| `USER_ID`            | UID of the user                             | `1000`                                   | `USER_ID=1001`            |
| `GROUP_ID`           | GID of the group                            | `1000`                                   | `GROUP_ID=1001`           |
| `PUBKEY`             | SSH public key for key-based authentication | -                                        | `PUBKEY=ssh-rsa AAAA...`  |

**Important**: Either PASS or PUBKEY must be specified. For better security, using SSH keys (PUBKEY) is recommended over passwords.

## Volume Configuration

The image uses two important volumes:

1. `/data/incoming`: Directory for file transfers
2. `/ssh`: Location for SSH host keys (optional, for persistence)

```bash
# Example with defined volumes
docker volume create sftp-data
docker volume create sftp-keys

docker run --name sftp -p 2222:22 \
  -v sftp-data:/data/incoming \
  -v sftp-keys:/ssh \
  -d mobilistics/sftp
```

## Connecting to the SFTP Server

### Command Line (Linux/macOS/Windows with OpenSSH)

```bash
# Connect with password (interactive input)
sftp -P 2222 sftp@localhost

# Connect with private key
sftp -P 2222 -i /path/to/private_key sftp@localhost
```

## Docker Compose Example

```yaml
version: "3"

services:
  sftp:
    image: mobilistics/sftp
    container_name: sftp-server
    ports:
      - "2222:22"
    volumes:
      - ./data:/data/incoming
      - ./ssh:/ssh
    environment:
      - USER=myuser
      - PASS=my_secure_password
      - USER_ID=1000
      - GROUP_ID=1000
    restart: unless-stopped
```

## Troubleshooting

### SSH/SFTP Connection Issues

```bash
# Check if the container is running
docker ps | grep sftp

# View container logs
docker logs sftp

# Enter the container for debugging
docker exec -it sftp bash
```
