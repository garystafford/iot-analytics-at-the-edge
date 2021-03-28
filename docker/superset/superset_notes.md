# Apache Superset Configuration

Reference: <https://hub.docker.com/r/apache/superset>

Build Docker container.

```shell
docker build -t garystafford/superset:1.0.0 .
docker push garystafford/superset:1.0.0
```

Configure Docker container.

```shell
SUPERSET_CONTAINER=$(docker ps -q \
    --filter='name=iot_superset.1' --format '{{.Names}}')
    
docker exec -it ${SUPERSET_CONTAINER} sh

docker exec -it ${SUPERSET_CONTAINER} \
  superset fab create-admin \
    --username admin \
    --firstname Superset \
    --lastname Admin \
    --email admin@superset.com \
    --password admin

docker exec -it ${SUPERSET_CONTAINER} \
  superset db upgrade

# docker exec -it ${SUPERSET_CONTAINER} \
#   superset load_examples

docker exec -it ${SUPERSET_CONTAINER} \
  superset init

docker exec -it ${SUPERSET_CONTAINER} \
  superset export_datasources
```

Copy and install datasource to superset container.

```shell
docker cp datasource.yml ${SUPERSET_CONTAINER}:/tmp

docker exec -it ${SUPERSET_CONTAINER} \
  superset import_datasources -p /tmp/datasource.yml
```