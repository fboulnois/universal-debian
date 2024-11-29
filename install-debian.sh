#!/bin/bash

##
# Debian 12 configuration script
##

set -eu

do_upgrade() {
  sudo apt-get update && sudo apt-get -y upgrade
}

##
# Development specific configuration
##

install_dev() {
  sudo apt-get install -y build-essential git git-lfs gdb curl jq pkg-config libssl-dev
}

setup_git() {
  git config --global credential.helper store
  git config --global init.defaultBranch main
  git config --global pull.rebase true
  git config --global push.autoSetupRemote true
  git config --global rebase.autoStash true
  git config --global alias.purge \!"git reflog expire --expire=now --all && git gc --prune=now --aggressive"
}

setup_rust() {
  cd "$HOME"
  RUST_SHA256="32a680a84cf76014915b3f8aa44e3e40731f3af92cd45eb0fcc6264fd257c428"
  curl -O https://raw.githubusercontent.com/rust-lang/rustup/1.27.1/rustup-init.sh
  echo "${RUST_SHA256}  rustup-init.sh" | sha256sum -c -
  chmod +x rustup-init.sh && ./rustup-init.sh -y && rm rustup-init.sh
  # shellcheck source=/dev/null
  source "$HOME/.cargo/env"
  cargo install cargo-deny --locked
  printf '[alias]\nwhy = "tree -i -p"\n' >> "$HOME/.cargo/config.toml"
}

setup_volta() {
  cd "$HOME"
  VOLTA_SHA256="743fa415bb238da4406e1350e69f85e1e6e2353489d8b825d7b5f8ee1b21311f"
  curl -O https://raw.githubusercontent.com/volta-cli/volta/v1.1.1/dev/unix/volta-install.sh
  echo "${VOLTA_SHA256}  volta-install.sh" | sha256sum -c -
  chmod +x volta-install.sh && ./volta-install.sh && rm volta-install.sh
}

setup_node() {
  printf 'alias yarn="pnpm"\n' >> "$HOME/.profile"
  export PATH="$HOME/.volta/bin:$PATH"
  volta install node@lts pnpm
}

ignore_docker_cli_hints() {
  printf 'export DOCKER_CLI_HINTS=false\n' >> "$HOME/.profile"
}

setup_dev() {
  install_dev
  setup_git
  setup_rust
  setup_volta
  setup_node
  ignore_docker_cli_hints
}

##
# WSL specific configuration
##

setup_ln() {
  WSLHOME=$(echo "${PATH}" | awk 'BEGIN{ RS=":" } /AppData/{ sub(/\/AppData.*/,"",$0) } END { print }')
  WSLPROJ="${WSLHOME}/Documents/Projects"
  if [ ! -d "${WSLPROJ}" ]; then
      >&2 echo "ERROR: Path ${WSLPROJ} does not exist"
      exit 1
  fi
  ln -s "${WSLPROJ}" "${HOME}/projects"
}

config_wsl() {
  sudo apt-get install -y wget
  WSL_CONFIG=$(cat << EOF
[automount]
enabled = true
options = "metadata"
mountFsTab = false
EOF
)
  echo "${WSL_CONFIG}" | sudo tee /etc/wsl.conf
  wsl.exe --set-default "${WSL_DISTRO_NAME}"
}

setup_wsl() {
  setup_ln
  config_wsl
}

##
# Server specific configuration
##

setup_utils() {
  sudo apt-get install -y \
    htop openssh-server unattended-upgrades ufw \
    apparmor apparmor-profiles apparmor-utils
}

setup_openssh() {
  echo "${SSH_AUTH_KEY}" | sudo tee /etc/ssh/authorized_keys
  sudo sed -i -r \
    -e 's/^#?LogLevel.*/LogLevel VERBOSE/' \
    -e 's/^#?PermitRootLogin.*/PermitRootLogin no/' \
    -e 's/^#?AuthorizedKeysFile.*/AuthorizedKeysFile \/etc\/ssh\/authorized_keys/' \
    -e 's/^#?PasswordAuthentication.*/PasswordAuthentication no/' \
    -e 's/^#?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' \
    -e 's/^#?X11Forwarding.*/X11Forwarding no/' \
      /etc/ssh/sshd_config
  sudo systemctl restart sshd
}

setup_ufw() {
  sudo ufw enable
  sudo ufw allow ssh
}

install_docker() {
  cd "$HOME"
  DOCKER_SHA256="a09e26b72228e330d55bf134b8eaca57365ef44bf70b8e27c5f55ea87a8b05e2"
  DOCKER_GPGFILE="docker-archive-bullseye-keyring.gpg"
  DOCKER_KEYRING="/usr/share/keyrings/${DOCKER_GPGFILE}"
  curl -s https://download.docker.com/linux/debian/gpg | gpg --batch --yes --dearmor -o "${DOCKER_GPGFILE}"
  echo "${DOCKER_SHA256}  ${DOCKER_GPGFILE}" | sha256sum -c -
  DOCKER_SIG=$(gpg --dry-run --show-keys "${DOCKER_GPGFILE}" | awk 'NR==2 { print $1 }')
  [ "${DOCKER_SIG}" = "9DC858229FC7DD38854AE2D88D81803C0EBFCD88" ]
  chmod 644 "${DOCKER_GPGFILE}" && sudo mv "${DOCKER_GPGFILE}" "${DOCKER_KEYRING}"
  echo "deb [signed-by=${DOCKER_KEYRING}] https://download.docker.com/linux/debian bullseye stable" | sudo tee /etc/apt/sources.list.d/docker.list
  sudo apt-get update && sudo apt-get install -y docker-ce
}

setup_docker() {
  # disable unprivileged user namespaces
  sudo sysctl -w user.max_user_namespaces=0
  # install docker and enable buildkit
  install_docker
  echo '{ "features": { "buildkit": true } }' | sudo tee /etc/docker/daemon.json
  sudo systemctl restart docker
  # make docker less painful to use without disabling sudo
  echo 'alias docker="sudo /usr/bin/docker"' >> "$HOME/.profile"
}

setup_server() {
  setup_utils
  setup_openssh
  setup_ufw
  setup_docker
}

do_upgrade

# dev config
#setup_dev

# wsl config
#setup_wsl

# server config -- ensure SSH_AUTH_KEY is exported
#setup_server
