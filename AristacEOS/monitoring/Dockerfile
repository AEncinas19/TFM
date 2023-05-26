FROM ubuntu:20.04
# install required packages
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Madrid
RUN apt-get clean
RUN apt-get update \
    && apt-get install -y \
    net-tools \
    traceroute \
    curl \
    iptables \
    inetutils-ping \
    nano \
    tcpdump \
    iperf3
COPY subscription-template-gnmic-eth1.json /
COPY subscription-template-gnmic-eth2.json /
RUN bash -c "$(curl -sL https://get-gnmic.openconfig.net)"
