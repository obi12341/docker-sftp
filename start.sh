#!/bin/sh
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

[ -z "$PASS" ] && [ -z "$PUBKEY" ] && error "Either PASS or PUBKEY must be provided"
case "$USER_ID" in
'' | *[!0-9]*) error "USER_ID must be a number" ;;
esac
case "$GROUP_ID" in
'' | *[!0-9]*) error "GROUP_ID must be a number" ;;
esac

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

if id "${USER}" >/dev/null 2>&1; then
  log "User ${USER} already exists"
else
  log "Creating user ${USER}"

  existing_user=$(grep ":${USER_ID}:" /etc/passwd | cut -d: -f1 || true)
  if [ -n "$existing_user" ]; then
    log "Removing existing user with ID ${USER_ID}: $existing_user"
    userdel "$existing_user" 2>/dev/null || true
  fi

  existing_group=$(grep ":${GROUP_ID}:" /etc/group | cut -d: -f1 || true)
  if [ -n "$existing_group" ]; then
    log "Removing existing group with ID ${GROUP_ID}: $existing_group"
    groupdel "$existing_group" 2>/dev/null || true
  fi

  addgroup -g ${GROUP_ID} sftp-only

  if [ -n "$PASS" ]; then
    # Use a more secure password hashing method
    adduser -h "$DATA_DIR" -G sftp-only -s /sbin/nologin -D -u ${USER_ID} ${USER}
    # Set password separately
    echo "${USER}:${PASS}" | chpasswd
  else
    adduser -h "$DATA_DIR" -G sftp-only -s /sbin/nologin -D -u ${USER_ID} ${USER}
    # Disable password login if using key authentication only
    passwd -l ${USER}
  fi
fi

log "Setting up directory permissions for chroot"
mkdir -p "$DATA_DIR"
chown root:root "$DATA_DIR"
chmod 755 "$DATA_DIR"

mkdir -p "$INCOMING_DIR"
chown ${USER}:sftp-only "$INCOMING_DIR"
chmod 755 "$INCOMING_DIR"

if [ -n "$PUBKEY" ]; then
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
