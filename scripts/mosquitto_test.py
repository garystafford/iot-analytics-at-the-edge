import argparse
import logging
import sys
from datetime import datetime

import paho.mqtt.publish as publish

# Test Message to Mosquitto Script
# Author: Gary A. Stafford
# Date: 2021-03-26
# Usage: python3 sensor_data_to_mosquitto.py \
#           --host "192.168.1.12" --port 1883 \
#           --topic "sensor/output"

logger = logging.getLogger(__name__)
logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)


def main():
    args = parse_args()
    publish_message_to_db(args)


def date_converter(o):
    if isinstance(o, datetime):
        return o.__str__()


def publish_message_to_db(args):
    sample_message_json = {"data": {"co": 0.004997145778992383, "humidity": 52.599998474121094, "light": False,
                                    "lpg": 0.007696788375166227, "motion": False, "smoke": 0.020542288909950537,
                                    "temperature": 20.600000381469727},
                           "device_id": "b8:27:eb:bf:9d:51", "time": "2021-03-27 00:49:05.081242+00:00"}
    logger.debug(sample_message_json)
    logger.debug(args)
    publish.single(args.topic, payload=sample_message_json, hostname=args.host, port=args.port)


# Read in command-line parameters
def parse_args():
    parser = argparse.ArgumentParser(description='Script arguments')
    parser.add_argument('--host', help='Mosquitto host', default='localhost')
    parser.add_argument('--port', help='Mosquitto port', type=int, default=1883)
    parser.add_argument('--topic', help='Mosquitto topic', default='paho/test')

    return parser.parse_args()


if __name__ == "__main__":
    main()
