# Telemetría del router
## Comandos:
kubectl -n monitoring apply -f deployment.yaml
kubectl -n monitoring apply -f service.yaml
Instalar curl y apt-get update
bash -c "$(curl -sL https://get-gnmic.openconfig.net)"

## Obtener métricas:
gnmic -a <IP_routerpod>:6030 -u admin -p admin --insecure --gzip get --path 'components/component/cpu'

