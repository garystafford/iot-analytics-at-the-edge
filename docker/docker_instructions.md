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

## Troubleshooting

Test Mosquitto directly. Log into two different sessions - sub and pub

```shell
MOSQUITTO_CONTAINER=$(docker ps -q \
    --filter='name=iot_mosquitto.1' --format '{{.Names}}')

docker exec -it ${MOSQUITTO_CONTAINER} sh

mosquitto_sub -d -t sensor/output

mosquitto_pub -d -t sensor/output -m '{"data":{"co":0.004965300196440765,"humidity":null,"light":true,"lpg":0.0
07661274225855072,"motion":false,"smoke":0.020441056991654268,"temperature":null},"device_id":"b8:27:eb:bf:9d:51","
time":"2021-03-26 16:03:24.437824+00:00"}'
```
