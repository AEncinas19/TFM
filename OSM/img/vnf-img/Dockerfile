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
    build-essential \
    bridge-utils \
    isc-dhcp-server \
    tcpdump \
    openvswitch-switch \
    openvswitch-common \
    iperf3 \
    iproute2 \
    vim \
    ryu-bin \
    arpwatch
COPY README.txt /
COPY vnx_config_nat /usr/bin/
COPY isc-dhcp-server /etc/default/isc-dhcp-server
COPY dhcpd.conf /etc/dhcp/dhcpd.conf 
COPY qos_simple_switch_13.py /
COPY node_exporter-1.5.0.linux-amd64.tar.gz /
RUN tar xvfz node_exporter-1.5.0.linux-amd64.tar.gz
RUN cd node_exporter-1.5.0.linux-amd64
CMD ./node_exporter
