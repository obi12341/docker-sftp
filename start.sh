#!/bin/bash
set -e

USER=${USER:-sftp}
USER_ID=${USER_ID:-1000}
GROUP_ID=${GROUP_ID:-1000}
PASS=${PASS:-}
DATA_DIR="/data"
INCOMING_DIR="${DATA_DIR}/incoming"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

error() {
  echo "ERROR: $1" >&2
  exit 1
}

[[ -z "$PASS" && -z "$PUBKEY" ]] && error "Either PASS or PUBKEY must be provided"
[[ "$USER_ID" =~ ^[0-9]+$ ]] || error "USER_ID must be a number"
[[ "$GROUP_ID" =~ ^[0-9]+$ ]] || error "GROUP_ID must be a number"

log "Checking SSH host keys..."
for type in rsa ecdsa ed25519; do
  if ! [ -e "/ssh/ssh_host_${type}_key" ]; then
    log "Generating /ssh/ssh_host_${type}_key..."
    ssh-keygen -f "/ssh/ssh_host_${type}_key" -N '' -t ${type}
    chmod 600 "/ssh/ssh_host_${type}_key"
  fi
  ln -sf "/ssh/ssh_host_${type}_key" "/etc/ssh/ssh_host_${type}_key"
  ln -sf "/ssh/ssh_host_${type}_key.pub" "/etc/ssh/ssh_host_${type}_key.pub"
done

if getent passwd ${USER} >/dev/null; then
  log "User ${USER} already exists"
else
  log "Creating user ${USER}"

  # Remove any existing user/group with the same ID to avoid conflicts
  existing_user=$(getent passwd ${USER_ID} | cut -d: -f1 || true)
  if [[ -n "$existing_user" ]]; then
    log "Removing existing user with ID ${USER_ID}: $existing_user"
    deluser "$existing_user"
  fi

  existing_group=$(getent group ${GROUP_ID} | cut -d: -f1 || true)
  if [[ -n "$existing_group" ]]; then
    log "Removing existing group with ID ${GROUP_ID}: $existing_group"
    delgroup "$existing_group"
  fi

  # Create group and user
  addgroup --gid ${GROUP_ID} sftp-only

  if [[ -n "$PASS" ]]; then
    # Use a more secure password hashing method if available
    if command -v mkpasswd >/dev/null; then
      ENC_PASS=$(mkpasswd -m sha-512 "${PASS}")
    else
      ENC_PASS=$(perl -e 'print crypt($ARGV[0], "\$6\$".substr(rand(), 2, 8))' "${PASS}")
    fi
    useradd -d "$DATA_DIR" -m -g sftp-only -p "${ENC_PASS}" -u ${USER_ID} -s /bin/false ${USER}
  else
    useradd -d "$DATA_DIR" -m -g sftp-only -u ${USER_ID} -s /bin/false ${USER}
  fi

  usermod -aG sftp-only ${USER}
fi

mkdir -p "$INCOMING_DIR"
chown ${USER}:sftp-only "$INCOMING_DIR"
chmod 0755 "$INCOMING_DIR"

if [[ -n "$PUBKEY" ]]; then
  SSH_DIR="${DATA_DIR}/.ssh"
  AUTH_KEYS="${SSH_DIR}/authorized_keys"

  mkdir -p "$SSH_DIR"
  touch "$AUTH_KEYS"

  if ! grep -q "$PUBKEY" "$AUTH_KEYS"; then
    log "Adding public key to authorized_keys"
    echo "$PUBKEY" >>"$AUTH_KEYS"
  fi

  chown -R ${USER}:sftp-only "$SSH_DIR"
  chmod 700 "$SSH_DIR"
  chmod 600 "$AUTH_KEYS"
fi

log "Starting SSHD..."
exec /usr/sbin/sshd -D -e
