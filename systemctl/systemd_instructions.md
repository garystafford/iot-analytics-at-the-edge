# Systemd Instructions

Clone git project to IoT sensors and gateway.

```shell
git clone --branch v2021-03 --single-branch --depth 1 \
    https://github.com/garystafford/iot-analytics-at-the-edge.git
```

Install and start `systemd` services.

```shell
# iot devices (sensors)
SERVICE=gtm_stack_mosquitto
sudo systemctl stop ${SERVICE}.service
sudo systemctl disable ${SERVICE}.service
sudo cp ${SERVICE}.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl start ${SERVICE}.service
sudo systemctl enable ${SERVICE}.service
systemctl status ${SERVICE}.service
ps aux | grep sensor_data_to_mosquitto.py

# edge node (gateways)
SERVICE=gtm_stack_mosq_to_tmscl
sudo systemctl stop ${SERVICE}.service
sudo systemctl disable ${SERVICE}.service
sudo cp ${SERVICE}.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl start ${SERVICE}.service
sudo systemctl enable ${SERVICE}.service
systemctl status ${SERVICE}.service
ps aux | grep mosquitto_to_timescaledb.py

# if service file changes
sudo systemctl daemon-reload

# other useful commands
sudo systemctl restart ${SERVICE}.service
sudo systemctl stop ${SERVICE}.service
sudo systemctl disable ${SERVICE}.service
```

`systemd` reference: <https://www.raspberrypi.org/documentation/linux/usage/systemd.md>