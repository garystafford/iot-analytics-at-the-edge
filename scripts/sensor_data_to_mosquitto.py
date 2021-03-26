import argparse
import json
import logging
import sys
import time
from datetime import datetime

import paho.mqtt.publish as publish
from Sensors import Sensors
from getmac import get_mac_address
from pytz import timezone

# Author: Gary A. Stafford
# Date: 10/11/2020
# Usage: python3 sensor_data_to_mosquitto.py \
#           --host "192.168.1.12" --port 1883 \
#           --topic "sensor/output" --frequency 10

sensors = Sensors()

logger = logging.getLogger(__name__)
logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)


def main():
    args = parse_args()
    publish_message_to_db(args)


def get_readings():
    sensors.led_state(0)

    # Retrieve sensor readings
    payload_dht = sensors.get_sensor_data_dht()
    payload_gas = sensors.get_sensor_data_gas()
    payload_light = sensors.get_sensor_data_light()
    payload_motion = sensors.get_sensor_data_motion()

    message = {
        "device_id": get_mac_address(),
        "time": datetime.now(timezone("UTC")),
        "data": {
            "temperature": payload_dht["temperature"],
            "humidity": payload_dht["humidity"],
            "lpg": payload_gas["lpg"],
            "co": payload_gas["co"],
            "smoke": payload_gas["smoke"],
            "light": payload_light["light"],
            "motion": payload_motion["motion"]
        }
    }

    return message


def date_converter(o):
    if isinstance(o, datetime):
        return o.__str__()


def publish_message_to_db(args):

    while True:
        message = get_readings()
        message_json = json.dumps(message, default=date_converter, sort_keys=True,
                                  indent=None, separators=(',', ':'))
        logger.debug(message_json)

        try:
            publish.single(args.topic, payload=message_json, hostname="192.168.1.12", port=9001)
        except Exception as error:
            logger.error("Exception: {}".format(error))
        finally:
            time.sleep(args.frequency)


# Read in command-line parameters
def parse_args():
    parser = argparse.ArgumentParser(description='Script arguments')
    parser.add_argument('--host', help='Mosquitto host', default='localhost')
    parser.add_argument('--port', help='Mosquitto port', type=int, default=1883)
    parser.add_argument('--topic', help='Mosquitto topic', default='paho/test')
    parser.add_argument('--frequency', help='Message frequency in seconds', type=int, default=5)

    return parser.parse_args()


if __name__ == "__main__":
    main()
