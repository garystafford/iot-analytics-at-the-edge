# Systemd Instructions

reference: https://www.raspberrypi.org/documentation/linux/usage/systemd.md

```bash
# IoT Devices
SERVICE=gtm_stack_mosquitto
sudo cp ${SERVICE}.service /etc/systemd/system/
sudo systemctl stop ${SERVICE}.service
sudo systemctl start ${SERVICE}.service
sudo systemctl enable ${SERVICE}.service
systemctl status ${SERVICE}
ps aux | grep sensor_data_to_mosquitto.py

sudo systemctl restart ${SERVICE}.service
systemctl status ${SERVICE}

# Edge Node
SERVICE=gtm_stack_mosq_to_tmscl
sudo cp ${SERVICE}.service /etc/systemd/system/
sudo systemctl stop ${SERVICE}.service
sudo systemctl start ${SERVICE}.service
sudo systemctl enable ${SERVICE}.service
systemctl status ${SERVICE}
ps aux | grep mosquitto_to_timescaledb.py

# if file changes
sudo systemctl daemon-reload

sudo systemctl restart ${SERVICE}.service
```