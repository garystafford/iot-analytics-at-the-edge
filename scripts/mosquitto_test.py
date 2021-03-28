import argparse
import logging
import sys

import paho.mqtt.publish as publish

# Test Message to Mosquitto Script
# Author: Gary A. Stafford
# Date: 2021-03-26
# Usage: python3 ./mosquitto_test.py --host "192.168.1.12" --port 1883

logger = logging.getLogger(__name__)
logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)


def main():
    publish_message_to_db(parse_args())


def publish_message_to_db(args):
    """Publish test message"""

    sample_message_json = {
        "data": {
            "co": 0.009,
            "humidity": 59.9,
            "light": False,
            "lpg": 0.009,
            "motion": False,
            "smoke": 0.009,
            "temperature": 19.9
        },
        "device_id": "00:00:00:00:00:00",
        "time": "2021-03-27 00:00:00.000000+00:00"
    }
    logger.debug(sample_message_json)
    publish.single('sensor/test', payload=str(sample_message_json), hostname=args.host, port=args.port)


def parse_args():
    """Read in command-line parameters"""

    parser = argparse.ArgumentParser(description='Script arguments')
    parser.add_argument('--host', help='Mosquitto host', default='localhost')
    parser.add_argument('--port', help='Mosquitto port', type=int, default=1883)

    return parser.parse_args()


if __name__ == '__main__':
    main()
