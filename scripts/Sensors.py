import logging
import sys

import Adafruit_DHT
from MQ import MQ
from gpiozero import LightSensor, MotionSensor, LED


# Author: Gary A. Stafford

class Sensors:

    def __init__(self, pin_dht=18, pin_light=24, pin_pir=23, pin_pir_led=25):
        self.pin_dht = pin_dht
        self.pin_light = pin_light
        self.pin_pir = pin_pir
        self.pin_pir_led = pin_pir_led

        # Initialize Temperature and Humidity Sensor
        self.sensor_dht = Adafruit_DHT.DHT22

        # Initialize and Calibrate Gas Sensor 1x
        self.mq = MQ()

        # Initialize Light Sensor
        self.ls = LightSensor(self.pin_light)

        # Initialize PIR Sensor
        self.pir = MotionSensor(self.pin_pir)
        self.led = LED(self.pin_pir_led)

        self.logger = logging.getLogger(__name__)
        logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)

    def led_state(self, desired_state):
        if desired_state == 0:
            self.led.off()
        else:
            self.led.on()

    def get_sensor_data_dht(self):
        try:
            humidity, temperature = Adafruit_DHT.read_retry(
                self.sensor_dht, self.pin_dht, delay_seconds=0)

            if humidity is None or humidity < 0 or humidity > 100 or temperature is None:
                raise RuntimeError

            payload = {
                "temperature": temperature,
                "humidity": humidity
            }
        except RuntimeError as err:
            # Errors happen fairly often, DHTs are hard to read, just keep going
            self.logger.error("RuntimeError: {}".format(err))
            payload = {
                "temperature": None,
                "humidity": None
            }
            return payload

        return payload

    def get_sensor_data_gas(self):
        try:
            mqp = self.mq.MQPercentage()
            payload = {
                "lpg": mqp["GAS_LPG"],
                "co": mqp["CO"],
                "smoke": mqp["SMOKE"]
            }
        except ValueError as err:
            self.logger.error("RuntimeError: {}".format(err))
            payload = {
                "lpg": None,
                "co": None,
                "smoke": None
            }

        return payload

    def get_sensor_data_light(self):
        if self.ls.value == 0.0:  # > 0.1:
            payload = {"light": True}
        else:
            payload = {"light": False}

        return payload

    def get_sensor_data_motion(self):
        if self.pir.value == 1.0:  # > 0.5:
            payload = {"motion": True}
            self.led.on()
        else:
            payload = {"motion": False}
            self.led.off()

        return payload
