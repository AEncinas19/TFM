# TFM de Aitor Encinas
En este Trabajo de Fin de Máster se despliega un escenario de red virtualizado que virtualiza las funciones de un CPE (DHCP, NAT, encaminamiento IP...) que se despliega en la central local de un operador de telecomunicaciones y que proporciona acceso a Internet a las redes corporativas que lo contraten.

## Manual de despliegue:
1) Seguir los requisitos de implementación previos disponibles en Requisitos de implementación, entre los que se incluye la descarga de la máquina virtual, la asignación de un proyecto en OSM, la descarga de este repositorio y la descarga de la imagen del router Arista.

2) Ejecutar el script deploy.sh situado en la ruta /TFM/OSM del repositorio principal para desplegar el escenario de red completo y configurado.
NOTA: si el NAT no funciona correctamente, acceder a la consola del router y en el directorio /mnt/flash ejecutar el siguiente comando: ./vnx_config_nat vlan1 eth2
y volver a probar su funcionamiento.

3) Ejecutar el script monitor.sh situado en la ruta /TFM/OSM del repositorio principal para desplegar el sistema de monitorización global.
NOTA: si los pods no se ejecutan correctamente y aparecen algunos en estado “Evicted”, comprobar las siguientes situaciones:

  - El tamaño de disco asignado a la máquina virtual es de al menos 64 GB.
  - Si al ejecutar en la terminal de la máquina virtual el comando ```$ df -h``` el espacio de disco asociado al espacio de almacenamiento principal (por ejemplo, /dev/mapper/Ubuntu--vg-ubuntu--lv) es menor de 60 GB, ampliarlo con el commando:
```$ sudo lvresize --resizefs --size +31GB /dev/mapper/ubuntu--vg-ubuntu--lv```
y eliminar el namespace monitoring de Kubernetes con el comando siguiente:
```$ kubectl delete ns monitoring```.

    Una vez realizado esto, volver a ejecutar el script monitor.sh.
Una vez completados estos pasos, el sistema ya estará disponible.
