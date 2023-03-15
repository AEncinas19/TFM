# Se utiliza la imagen de Ubuntu como base
FROM ghcr.io/nokia/srlinux

# Copiar el archivo de topología al contenedor
COPY topology.yml /tmp/topology.yml

WORKDIR /opt/srlinux
CMD sudo /opt/srlinux/bin/sr_linux

