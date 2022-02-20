#!/bin/bash

##
# Debian 11 configuration script
##

set -eu

do_upgrade() {
  sudo apt-get update && sudo apt-get -y upgrade
}

##
# Development specific configuration
##

install_dev() {
  sudo apt-get install -y build-essential git gdb curl jq pkg-config libssl-dev
}

setup_rust() {
  curl https://sh.rustup.rs | sh -s -- -y
  # shellcheck source=/dev/null
  source "$HOME/.cargo/env"
  cargo install cargo-deny
}

setup_nvm() {
  cd "$HOME"
  curl https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
  # shellcheck source=/dev/null
  source "$HOME/.nvm/nvm.sh"
  nvm install 16
  npm install -g yarn
  echo "enableTelemetry: 0" > "$HOME/.yarnrc.yml"
  yarn set version stable && rm package.json
  sed -i '/^$/d' .yarnrc.yml
}

setup_dev() {
  install_dev
  setup_rust
  setup_nvm
}

##
# WSL specific configuration
##

setup_ln() {
  WINHOME=$(echo "${PATH}" | sed 's/:/\n/g' | grep -m 1 WindowsApps | sed 's/\/AppData.*//')
  WSLHOME=$(wslpath "${WINHOME}" 2>&1 | sed 's/wslpath: //')
  WSLPROJ="${WSLHOME}/Documents/Projects"
  if [ ! -d "${WSLPROJ}" ]; then
      >&2 echo "ERROR: Path ${WSLPROJ} does not exist"
      exit 1
  fi
  ln -s "${WSLPROJ}" "${HOME}/projects"
}

config_wsl() {
  sudo apt-get install -y wget
  sudo cp wsl.conf /etc/wsl.conf
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
  echo "${SSHD_CONFIG}" | sudo tee /etc/ssh/authorized_keys
  sudo sed -i -r \
    -e 's/^#?AuthorizedKeysFile.*/AuthorizedKeysFile \/etc\/ssh\/authorized_keys/' \
    -e 's/^#?PasswordAuthentication.*/PasswordAuthentication no/' \
      /etc/ssh/sshd_config
  sudo systemctl restart sshd
}

setup_ufw() {
  sudo ufw enable
  sudo ufw allow ssh
}

setup_docker() {
  # disable unprivileged user namespaces
  sudo sysctl -w kernel.unprivileged_userns_clone=0
  # install docker and enable buildkit
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 9DC858229FC7DD38854AE2D88D81803C0EBFCD88
  echo "deb [arch=amd64] https://download.docker.com/linux/debian bullseye stable" | sudo tee /etc/apt/sources.list.d/docker.list
  sudo apt-get update && sudo apt-get install -y docker-ce
  echo '{ "features": { "buildkit": true } }' | sudo tee /etc/docker/daemon.json
  sudo systemctl restart docker
  # make docker less painful to use without disabling sudo
  echo 'alias docker="sudo /usr/bin/docker"' >> "$HOME/.bashrc"
}

setup_server() {
  setup_utils
  setup_openssh
  setup_ufw
  setup_docker
}

##
# Intel NUC specific configuration
##

setup_iwd() {
  sudo sed -i 's/main$/main contrib non-free/' /etc/apt/sources.list
  sudo apt-get update && sudo apt-get install -y firmware-iwlwifi iwd
}

config_iwd() {
  # configure iwd to use default dhcp and ivp6
  IWD_CONFIG=$(cat << EOF
[General]
EnableNetworkConfiguration=true

[Network]
EnableIPv6=true
EOF
)
  echo "${IWD_CONFIG}" | sudo tee /etc/iwd/main.conf
  # connect to wireless network
  read -r -s -p "Wireless SSID: " IWD_SSID
  read -r -s -p "Wireless passphrase: " IWD_PASS
  iwctl --passphrase "${IWD_PASS}" static wlan0 connect "${IWD_SSID}"
}

setup_nuc() {
  setup_iwd
  config_iwd
}

do_upgrade

# dev config
#setup_dev

# wsl config
#setup_wsl

# server config -- ensure SSHD_CONFIG is exported
#setup_server

# nuc config
#setup_nuc
