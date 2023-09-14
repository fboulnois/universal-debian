FROM debian:12-slim

RUN apt update && apt install -y sudo curl nano shellcheck

RUN useradd -m debian \
  && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
  && usermod -aG sudo debian

USER debian

WORKDIR /home/debian

ARG WSL_DISTRO_NAME="Debian"
ARG HOME="/home/debian"
ARG PATH="$PATH:$HOME/AppData"

COPY install-debian.sh .

RUN mkdir -p "$HOME/Documents/Projects" \
  && sed -i \
    -e 's/^#setup_dev/setup_dev/' \
    -e 's/^#setup_wsl/setup_wsl/' \
    -e 's/wsl\.exe/echo/' \
    install-debian.sh \
  && shellcheck install-debian.sh \
  && ./install-debian.sh
