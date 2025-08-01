#!/bin/bash

##
# Debian 12 configuration script
##

set -eu

do_upgrade() {
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
  git config --global alias.purge \!"git reflog expire --expire=now --all && git gc --prune=now --aggressive"
}

setup_rust() {
  cd "$HOME"
  RUST_SHA256="17247e4bcacf6027ec2e11c79a72c494c9af69ac8d1abcc1b271fa4375a106c2"
  curl -O https://raw.githubusercontent.com/rust-lang/rustup/1.28.2/rustup-init.sh
  echo "${RUST_SHA256}  rustup-init.sh" | sha256sum -c -
  chmod +x rustup-init.sh && ./rustup-init.sh -y && rm rustup-init.sh
  # shellcheck source=/dev/null
  source "$HOME/.cargo/env"
  cargo install cargo-deny --locked
  cargo install cargo-llvm-cov --locked
  printf '[alias]\nwhy = "tree --target all --invert --package"\n' >> "$HOME/.cargo/config.toml"
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
# Docker configuration
##

install_docker() {
  cd "$HOME"
  DOCKER_SHA256="a09e26b72228e330d55bf134b8eaca57365ef44bf70b8e27c5f55ea87a8b05e2"
  DOCKER_GPGFILE="docker-keyring.gpg"
  DOCKER_KEYRING="/usr/share/keyrings/${DOCKER_GPGFILE}"
  curl -s https://download.docker.com/linux/debian/gpg | gpg --batch --yes --dearmor -o "${DOCKER_GPGFILE}"
  echo "${DOCKER_SHA256}  ${DOCKER_GPGFILE}" | sha256sum -c -
  DOCKER_SIG=$(gpg --dry-run --show-keys "${DOCKER_GPGFILE}" | awk 'NR==2 { print $1 }')
  [ "${DOCKER_SIG}" = "9DC858229FC7DD38854AE2D88D81803C0EBFCD88" ]
  chmod 644 "${DOCKER_GPGFILE}" && sudo mv "${DOCKER_GPGFILE}" "${DOCKER_KEYRING}"
  echo "deb [signed-by=${DOCKER_KEYRING}] https://download.docker.com/linux/debian bookworm stable" | sudo tee /etc/apt/sources.list.d/docker.list
  sudo apt-get update && sudo apt-get install -y docker-ce
}

setup_nvctk() {
  cd "$HOME"
  NVCTK_SHA256="425822bb25bfa7f5ce96e598a7bbd27db128649e4113017b3ff765b98b43b166"
  NVCTK_GPGFILE="nvidia-container-toolkit-keyring.gpg"
  NVCTK_KEYRING="/usr/share/keyrings/${NVCTK_GPGFILE}"
  curl -s https://nvidia.github.io/libnvidia-container/gpgkey | gpg --batch --yes --dearmor -o "${NVCTK_GPGFILE}"
  echo "${NVCTK_SHA256}  ${NVCTK_GPGFILE}" | sha256sum -c -
  NVCTK_SIG=$(gpg --dry-run --show-keys "${NVCTK_GPGFILE}" | awk 'NR==2 { print $1 }')
  [ "${NVCTK_SIG}" = "C95B321B61E88C1809C4F759DDCAE044F796ECB0" ]
  chmod 644 "${NVCTK_GPGFILE}" && sudo mv "${NVCTK_GPGFILE}" "${NVCTK_KEYRING}"
  echo "deb [signed-by=${NVCTK_KEYRING}] https://nvidia.github.io/libnvidia-container/stable/deb/amd64 /" | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
  sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
  sudo nvidia-ctk runtime configure --runtime=docker
}

setup_docker() {
  # disable unprivileged user namespaces
  sudo sysctl -w user.max_user_namespaces=0
  # install docker and enable buildkit
  install_docker
  sudo systemctl restart docker
  # make docker less painful to use without disabling sudo
  echo 'alias docker="sudo /usr/bin/docker"' >> "$HOME/.profile"
}

##
# WSL configuration
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

[boot]
command = "service docker start"
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
# Server configuration
##

setup_openssh() {
  sudo apt-get install -y openssh-server
  sudo sed -i -r \
    -e 's/^#?LogLevel.*/LogLevel VERBOSE/' \
    -e 's/^#?PermitRootLogin.*/PermitRootLogin no/' \
    -e 's/^#?AuthorizedKeysFile.*/AuthorizedKeysFile \/etc\/ssh\/authorized_keys/' \
    -e 's/^#?PasswordAuthentication.*/PasswordAuthentication no/' \
    -e 's/^#?X11Forwarding.*/X11Forwarding no/' \
      /etc/ssh/sshd_config
  sudo systemctl restart sshd
}

setup_ufw() {
  sudo ufw enable
  sudo ufw allow ssh
}

setup_server() {
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
