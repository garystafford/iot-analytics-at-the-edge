# Docker Instructions

```shell
docker run --name tmp_mosquitto -p 1884:1883 eclipse-mosquitto:2.0.9
docker exec -it tmp_mosquitto cat /mosquitto/config/mosquitto.conf eclipse-mosquitto
docker rm -f tmp_mosquitto
```

```shell
mkdir -p ~/data/postgres
mkdir -p ~/data/grafana
mkdir -p ~/data/mosquitto/config
```
```shell
EDGE_DEVICE_HOST=192.168.1.12
scp -i ~/.ssh/rasppi docker/mosquitto.conf \
  pi@${EDGE_DEVICE_HOST}:~/data/mosquitto/config/
```

```shell
docker swarm init
docker stack deploy -c stack.yml iot
docker stack ps iot --no-trunc
docker stack services iot
```

```text
ID             NAME              MODE         REPLICAS   IMAGE                              PORTS
c9mwb57p7fvj   iot_grafana       replicated   1/1        grafana/grafana:7.5.0              *:3000->3000/tcp
4jhihwja0ct6   iot_mosquitto     replicated   1/1        eclipse-mosquitto:2.0.9            *:1883->1883/tcp
woyaqpiohu7c   iot_pgadmin       replicated   1/1        biarms/pgadmin4:4.21               *:5050->5050/tcp
ij1huytkfh5c   iot_timescaledb   replicated   1/1        timescale/timescaledb:2.0.0-pg12   *:5432->5432/tcp
```

```shell
docker stack rm iot
```
