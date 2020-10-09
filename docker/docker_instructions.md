# Docker Instructions

```bash
mkdir -p ~/data/postgres
mkdir -p ~/data/grafana
mkdir -p ~/data/mosquitto/config

EDGE_DEVICE_HOST=192.168.1.12

scp -i ~/.ssh/rasppi docker/mosquitto.conf \
  pi@${EDGE_DEVICE_HOST}:~/data/mosquitto/config/

docker swarm init
docker stack deploy -c stack.yml iot
docker stack ps iot --no-trunc
docker stack services iot
```
