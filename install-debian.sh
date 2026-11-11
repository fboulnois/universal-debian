#!/bin/bash

##
# Debian 13 configuration script
##

set -eu

do_upgrade() {
  for SOURCES in /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; do
    if [ -f "${SOURCES}" ]; then
      sudo sed -i -E 's#http://(deb|security)\.debian\.org/#https://\1.debian.org/#g' "${SOURCES}"
    fi
  done
  sudo apt-get update && sudo apt-get -y upgrade
}

##
# Development configuration
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
}

setup_rust() {
  cd "$HOME"
  RUST_SHA256="d890e2fef6fa991b19cde2e608199bc1dca4e37f41f884edf8849ff693048de6"
  curl -O https://raw.githubusercontent.com/rust-lang/rustup/1.29.3/rustup-init.sh
  echo "${RUST_SHA256}  rustup-init.sh" | sha256sum -c -
  chmod +x rustup-init.sh && ./rustup-init.sh -y && rm rustup-init.sh
  # shellcheck source=/dev/null
  source "$HOME/.cargo/env"
  cargo install --locked cargo-deny cargo-llvm-cov cargo-msrv
  if ! grep -qxF '[alias]' "$HOME/.cargo/config.toml" 2>/dev/null; then
    printf '[alias]\nwhy = "tree --target all --invert --package"\n' >> "$HOME/.cargo/config.toml"
  fi
}

setup_volta() {
  cd "$HOME"
  VOLTA_SHA256="fbdc4b8cb33fb6d19e5f07b22423265943d34e7e5c3d5a1efcecc9621854f9cb"
  curl -O https://raw.githubusercontent.com/volta-cli/volta/v2.0.2/dev/unix/volta-install.sh
  echo "${VOLTA_SHA256}  volta-install.sh" | sha256sum -c -
  chmod +x volta-install.sh && ./volta-install.sh && rm volta-install.sh
}

setup_node() {
  export PATH="$HOME/.volta/bin:$PATH"
  volta install node@lts pnpm
}

setup_dev() {
  install_dev
  setup_git
  setup_rust
  setup_volta
  setup_node
}

##
# Docker configuration
##

install_docker_prereqs() {
  sudo apt-get install -y curl gnupg
  mkdir -p "$HOME/.gnupg"
  chmod 700 "$HOME/.gnupg"
}

disable_unprivileged_userns() {
  if [ -e /proc/sys/kernel/unprivileged_userns_clone ]; then
    echo 'kernel.unprivileged_userns_clone = 0' | sudo tee /etc/sysctl.d/99-userns.conf
    sudo sysctl --system
  fi
}

install_docker() {
  cd "$HOME"
  DOCKER_SHA256="a09e26b72228e330d55bf134b8eaca57365ef44bf70b8e27c5f55ea87a8b05e2"
  DOCKER_GPGFILE="docker-keyring.gpg"
  DOCKER_KEYRING="/usr/share/keyrings/${DOCKER_GPGFILE}"
  curl -s https://download.docker.com/linux/debian/gpg | gpg --batch --yes --dearmor -o "${DOCKER_GPGFILE}"
  echo "${DOCKER_SHA256}  ${DOCKER_GPGFILE}" | sha256sum -c -
  chmod 644 "${DOCKER_GPGFILE}" && sudo mv "${DOCKER_GPGFILE}" "${DOCKER_KEYRING}"
  echo "deb [signed-by=${DOCKER_KEYRING}] https://download.docker.com/linux/debian trixie stable" | sudo tee /etc/apt/sources.list.d/docker.list
  sudo apt-get update && sudo apt-get install -y docker-ce
}

setup_docker() {
  install_docker_prereqs
  disable_unprivileged_userns
  install_docker
  sudo systemctl restart docker
}

setup_docker_nosudo() {
  setup_docker
  sudo usermod -aG docker "$USER"
}

install_nvctk() {
  cd "$HOME"
  NVCTK_SHA256="425822bb25bfa7f5ce96e598a7bbd27db128649e4113017b3ff765b98b43b166"
  NVCTK_GPGFILE="nvidia-container-toolkit-keyring.gpg"
  NVCTK_KEYRING="/usr/share/keyrings/${NVCTK_GPGFILE}"
  curl -s https://nvidia.github.io/libnvidia-container/gpgkey | gpg --batch --yes --dearmor -o "${NVCTK_GPGFILE}"
  echo "${NVCTK_SHA256}  ${NVCTK_GPGFILE}" | sha256sum -c -
  chmod 644 "${NVCTK_GPGFILE}" && sudo mv "${NVCTK_GPGFILE}" "${NVCTK_KEYRING}"
  echo "deb [signed-by=${NVCTK_KEYRING}] https://nvidia.github.io/libnvidia-container/stable/deb/amd64 /" | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
  sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
  sudo nvidia-ctk runtime configure --runtime=docker
}

setup_nvctk() {
  if ! command -v dockerd &> /dev/null; then
    echo "--nvctk requires --docker or --docker-nosudo before it" 1>&2
    exit 1
  fi
  install_nvctk
  sudo systemctl restart docker
}

##
# WSL configuration
##

setup_ln() {
  WSLHOME=$(echo "${PATH}" | awk 'BEGIN{ RS=":" } /AppData/{ sub(/\/AppData.*/,"",$0) } END { print }')
  WSLPROJ="${WSLHOME}/Documents/Projects"
  if [ -d "${WSLPROJ}" ] && [ ! -e "${HOME}/projects" ] && [ ! -L "${HOME}/projects" ]; then
    ln -s "${WSLPROJ}" "${HOME}/projects"
  fi
  WSLSSH="${WSLHOME}/.ssh"
  if [ -d "${WSLSSH}" ] && [ ! -e "${HOME}/.ssh" ] && [ ! -L "${HOME}/.ssh" ]; then
    ln -s "${WSLSSH}" "${HOME}/.ssh"
  fi
}

config_wsl() {
  sudo apt-get install -y wget
  WSL_CONFIG=$(cat << EOF
[automount]
enabled = true
options = "metadata"
mountFsTab = false

[boot]
command = "service docker start"
EOF
)
  echo "${WSL_CONFIG}" | sudo tee /etc/wsl.conf
}

setup_wsl() {
  setup_ln
  config_wsl
}

##
# Server configuration
##

setup_openssh() {
  sudo apt-get install -y openssh-server
  SSHD_CONFIG=$(cat << EOF
LogLevel VERBOSE
PermitRootLogin no
AuthorizedKeysFile /etc/ssh/authorized_keys
PasswordAuthentication no
KbdInteractiveAuthentication no
X11Forwarding no
EOF
)
  if [ ! -s /etc/ssh/authorized_keys ] || [ ! -r /etc/ssh/authorized_keys ]; then
    echo "/etc/ssh/authorized_keys is missing, empty, or unreadable" 1>&2
    exit 1
  fi
  echo "${SSHD_CONFIG}" | sudo tee /etc/ssh/sshd_config.d/00-hardening.conf
  sudo sshd -t
  sudo systemctl restart sshd
}

setup_ufw() {
  sudo apt-get install -y ufw
  sudo ufw allow ssh
  sudo ufw --force enable
}

setup_server() {
  disable_unprivileged_userns
  setup_openssh
  setup_ufw
}

do_upgrade

for ARG in "$@"; do
  case $ARG in
    --dev)
      setup_dev
      shift
      ;;
    --docker)
      setup_docker
      shift
      ;;
    --docker-nosudo)
      setup_docker_nosudo
      shift
      ;;
    --nvctk)
      setup_nvctk
      shift
      ;;
    --wsl)
      setup_wsl
      shift
      ;;
    --server)
      setup_server
      shift
      ;;
    *)
      echo "Invalid option: $ARG" 1>&2
      ;;
  esac
done
