import argparse
import json
import logging
import sys
from datetime import datetime

import paho.mqtt.client as mqtt
import psycopg2

# Author: Gary A. Stafford
# Date: 10/11/2020
# Usage: python3 mosquitto_to_timescaledb.py \
#           --msqt_topic "sensor/output --msqt_host "192.168.1.12" --msqt_port 1883 \
#           --ts_host "192.168.1.12" --ts_port 5432 \
#           --ts_username postgres --ts_password postgres1234 --ts_database demo_iot

logger = logging.getLogger(__name__)
logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)

args = argparse.Namespace
ts_connection: str = ""


def main():
    global args
    args = parse_args()

    global ts_connection
    ts_connection = "postgres://{}:{}@{}:{}/{}".format(args.ts_username, args.ts_password, args.ts_host,
                                                       args.ts_port, args.ts_database)
    logger.debug("TimescaleDB connection: {}".format(ts_connection))

    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_message = on_message

    client.connect(args.msqt_host, args.msqt_port, 60)

    # Blocking call that processes network traffic, dispatches callbacks and
    # handles reconnecting.
    # Other loop*() functions are available that give a threaded interface and a
    # manual interface.
    client.loop_forever()


# The callback for when the client receives a CONNACK response from the server.
def on_connect(client, userdata, flags, rc):
    logger.debug("Connected with result code {}".format(str(rc)))

    # Subscribing in on_connect() means that if we lose the connection and
    # reconnect then subscriptions will be renewed.
    client.subscribe(args.msqt_topic)


# The callback for when a PUBLISH message is received from the server.
def on_message(client, userdata, msg):
    logger.debug("Topic: {}, Message Payload: {}".format(msg.topic, str(msg.payload)))
    publish_message_to_db(msg)


def date_converter(o):
    if isinstance(o, datetime):
        return o.__str__()


def publish_message_to_db(message):
    message_payload = json.loads(message.payload)
    # logger.debug("message.payload: {}".format(json.dumps(message_payload, default=date_converter)))

    sql = """INSERT INTO sensor_data(time, device_id, temperature, humidity, lpg, co, smoke, light, motion)
                 VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s);"""

    data = (
        message_payload["time"], message_payload["device_id"], message_payload["data"]["temperature"],
        message_payload["data"]["humidity"], message_payload["data"]["lpg"], message_payload["data"]["co"],
        message_payload["data"]["smoke"], message_payload["data"]["light"], message_payload["data"]["motion"])

    try:
        with psycopg2.connect(ts_connection, connect_timeout=3) as conn:
            with conn.cursor() as curs:
                try:
                    curs.execute(sql, data)
                except psycopg2.Error as error:
                    logger.error("Exception: {}".format(error.pgerror))
                except Exception as error:
                    logger.error("Exception: {}".format(error))
    except psycopg2.OperationalError as error:
        logger.error("Exception: {}".format(error.pgerror))
    finally:
        conn.close()


# Read in command-line parameters
def parse_args():
    parser = argparse.ArgumentParser(description='Script arguments')
    parser.add_argument('--msqt_topic', help='Mosquitto topic', default='paho/test')
    parser.add_argument('--msqt_host', help='Mosquitto host', default='localhost')
    parser.add_argument('--msqt_port', help='Mosquitto port', type=int, default=1883)
    parser.add_argument('--ts_host', help='TimescaleDB host', default='localhost')
    parser.add_argument('--ts_port', help='TimescaleDB port', type=int, default=5432)
    parser.add_argument('--ts_username', help='TimescaleDB username', default='postgres')
    parser.add_argument('--ts_password', help='TimescaleDB password', default='postgres1234')
    parser.add_argument('--ts_database', help='TimescaleDB password', default='demo_iot')

    return parser.parse_args()


if __name__ == "__main__":
    main()
