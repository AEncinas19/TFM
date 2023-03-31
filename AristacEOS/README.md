## 1. Importación de la imagen docker (OSM):
docker import cEOS64-lab-4.29.2F.tar.tar ceos:4.29.0.2F
## 2. Meter en el registry de microk8s:
sudo docker tag ceos:4.29.0.2F 192.168.56.11:32000/ceos:latest
## 3. Modificar helm chart del router
