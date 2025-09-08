FROM debian:13-slim

RUN apt update && apt install -y sudo curl nano shellcheck

COPY install-debian.sh .

RUN shellcheck install-debian.sh
