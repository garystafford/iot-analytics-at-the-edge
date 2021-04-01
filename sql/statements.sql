CREATE DATABASE demo_iot;
\c

CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

-- iot data table
CREATE TABLE IF NOT EXISTS sensor_data
(
    time        timestamptz      NOT NULL,
    device_id   text             NOT NULL,
    temperature double PRECISION NOT NULL,
    humidity    double PRECISION NOT NULL,
    lpg         double PRECISION NOT NULL,
    co          double PRECISION NOT NULL,
    smoke       double PRECISION NOT NULL,
    light       boolean          NOT NULL,
    motion      boolean          NOT NULL
);

SELECT create_hypertable('sensor_data', 'time');

TRUNCATE sensor_data;
SELECT count(*) FROM sensor_data;
SELECT * FROM sensor_data limit 10;

--views
-- temperature and humidity
CREATE MATERIALIZED VIEW temperature_humidity_summary_minute WITH (timescaledb.continuous) AS
SELECT device_id,
       time_bucket(INTERVAL '1 minute', time) AS bucket,
       avg(temperature) AS avg_temp,
       avg(humidity) AS avg_humidity
FROM sensor_data
WHERE humidity >= 0.0
  AND humidity <= 100.0
GROUP BY device_id,
         bucket
ORDER BY bucket;

-- air quality (lpg, co, smoke)
CREATE MATERIALIZED VIEW air_quality_summary_minute WITH (timescaledb.continuous) AS
SELECT device_id,
       time_bucket(INTERVAL '1 minute', time) AS bucket,
       avg(lpg) AS avg_lpg,
       avg(co) AS avg_co,
       avg(smoke) AS avg_smoke
FROM sensor_data
GROUP BY device_id,
         bucket;

-- light
CREATE MATERIALIZED VIEW light_summary_minute WITH (timescaledb.continuous) AS
SELECT device_id,
       time_bucket(INTERVAL '1 minute', time) AS bucket,
       avg(
               case
                   when light = 't' then 1
                   else 0
                   end
           ) AS avg_light
FROM sensor_data
GROUP BY device_id,
         bucket;

-- motion
CREATE MATERIALIZED VIEW motion_summary_minute WITH (timescaledb.continuous) AS
SELECT device_id,
       time_bucket(INTERVAL '1 minute', time) AS bucket,
       avg(
               case
                   when motion = 't' then 1
                   else 0
                   end
           ) AS avg_motion
FROM sensor_data
GROUP BY device_id,
         bucket;


-- grafana user and grants
CREATE USER grafanareader WITH PASSWORD 'grafana1234';
GRANT USAGE ON SCHEMA public TO grafanareader;
GRANT SELECT ON public.sensor_data TO grafanareader;
GRANT SELECT ON public.temperature_humidity_summary_minute TO grafanareader;
GRANT SELECT ON public.air_quality_summary_minute TO grafanareader;
GRANT SELECT ON public.light_summary_minute TO grafanareader;
GRANT SELECT ON public.motion_summary_minute TO grafanareader;

-- query views
SELECT *
FROM temperature_humidity_summary_minute
ORDER BY bucket;


-- ad-hoc queries
-- find max temperature (°C) and humidity (%) for last 3 hours in 15 minute time periods
-- https://docs.timescale.com/latest/using-timescaledb/reading-data#select
SELECT time_bucket('15 minutes', time) AS fifteen_min,
       device_id,
       count(*),
       max(temperature) AS max_temp,
       max(humidity) AS max_hum
FROM sensor_data
WHERE time > now() - INTERVAL '3 hours'
  AND humidity BETWEEN 0 AND 100
GROUP BY fifteen_min, device_id
ORDER BY fifteen_min DESC, max_temp desc;

-- find temperature (°C) anomalies (delta > ~5°F)
-- https://docs.timescale.com/latest/using-timescaledb/reading-data#delta
WITH ht AS (SELECT time,
                   temperature,
                   abs(temperature - lag(temperature) over (ORDER BY time)) AS delta
            FROM sensor_data)
SELECT ht.time, ht.temperature, ht.delta
FROM ht
WHERE ht.delta > 2.63
ORDER BY ht.time;

-- find three minute moving average of temperature (°F) for last day
-- (5 sec. interval * 36 rows = 3 min.)
-- https://docs.timescale.com/latest/using-timescaledb/reading-data#moving-average
SELECT time,
       avg((temperature * 1.9) + 32) over (ORDER BY time
           ROWS BETWEEN 35 PRECEDING AND CURRENT ROW)
           AS smooth_temp
FROM sensor_data
WHERE device_id = 'Manufacturing Plant'
    AND time > now() - INTERVAL '1 day'
ORDER BY time desc;

-- find average humidity (%) for last 12 hours in 5-minute time periods
-- https://docs.timescale.com/latest/using-timescaledb/reading-data#time-bucket
SELECT time_bucket('5 minutes', time) AS time_period,
       avg(humidity)                  AS avg_humidity
FROM sensor_data
WHERE device_id = 'Main Warehouse'
  AND humidity BETWEEN 0 AND 100
  AND time > now() - INTERVAL '12 hours'
GROUP BY time_period
ORDER BY time_period desc;

-- calculate histograms of avg. temperature (°F) between 55-85°F in 5°F buckets during last 2 days
-- https://docs.timescale.com/latest/using-timescaledb/reading-data#histogram
SELECT device_id,
       count(*),
       histogram((temperature * 1.9) + 32, 55.0, 85.0, 5)
FROM sensor_data
WHERE temperature is not Null
    AND time > now() - INTERVAL '2 days'
GROUP BY device_id;

-- find average light value for last 90 minutes in 5-minute time periods
-- https://docs.timescale.com/latest/using-timescaledb/reading-data#time-bucket
SELECT device_id,
       time_bucket('5 minutes', time) AS five_min,
       avg(case when light = 't' then 1 else 0 end) AS avg_light
FROM sensor_data
WHERE device_id = 'Manufacturing Plant'
    AND time > now() - INTERVAL '90 minutes'
GROUP BY device_id, five_min
ORDER BY five_min desc;
