CREATE DATABASE demo_iot;
\c

CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

CREATE SCHEMA public;

-- iot data table
CREATE TABLE IF NOT EXISTS public.sensor_data
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

-- TRUNCATE sensor_data;
SELECT count(*) FROM sensor_data;
SELECT * FROM sensor_data limit 10;

-- materialized views
-- temperature and humidity
CREATE MATERIALIZED VIEW temperature_humidity_summary_minute(device_id, bucket, avg_temp, avg_humidity)
    WITH (timescaledb.continuous) AS
        SELECT device_id,
               time_bucket(INTERVAL '1 minute', time),
               avg(temperature),
               avg(humidity)
        FROM sensor_data
        WHERE humidity >= 0.0 AND humidity <= 100.0
        GROUP BY device_id, time_bucket(INTERVAL '1 minute', time)
    WITH NO DATA;

-- air quality (lpg, co, smoke)
CREATE MATERIALIZED VIEW air_quality_summary_minute(device_id, bucket, avg_lpg, avg_co, avg_smoke)
    WITH (timescaledb.continuous) AS
        SELECT device_id,
               time_bucket(INTERVAL '1 minute', time),
               avg(lpg),
               avg(co),
               avg(smoke)
        FROM sensor_data
        GROUP BY device_id, time_bucket(INTERVAL '1 minute', time)
    WITH NO DATA;

-- light
CREATE MATERIALIZED VIEW light_summary_minute(device_id, bucket, avg_light)
    WITH (timescaledb.continuous) AS
        SELECT device_id,
               time_bucket(INTERVAL '1 minute', time),
               avg(
                       case
                           when light = 't' then 1
                           else 0
                           end
                   )
        FROM sensor_data
        GROUP BY device_id, time_bucket(INTERVAL '1 minute', time)
    WITH NO DATA;

-- motion
CREATE MATERIALIZED VIEW motion_summary_minute(device_id, bucket, avg_motion)
    WITH (timescaledb.continuous) AS
        SELECT device_id,
               time_bucket(INTERVAL '1 minute', time),
               avg(
                       case
                           when motion = 't' then 1
                           else 0
                           end
                   )
        FROM sensor_data
        GROUP BY device_id, time_bucket(INTERVAL '1 minute', time)
    WITH NO DATA;

drop materialized view air_quality_summary_minute;
drop materialized view light_summary_minute;
drop materialized view motion_summary_minute;
drop materialized view temperature_humidity_summary_minute;

-- Create a policy that automatically refreshes a continuous aggregate
SELECT add_continuous_aggregate_policy('air_quality_summary_minute',
    start_offset => INTERVAL '1 week',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour');

SELECT add_continuous_aggregate_policy('light_summary_minute',
    start_offset => INTERVAL '1 week',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour');

SELECT add_continuous_aggregate_policy('motion_summary_minute',
    start_offset => INTERVAL '1 week',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour');

SELECT add_continuous_aggregate_policy('temperature_humidity_summary_minute',
    start_offset => INTERVAL '1 week',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour');

SELECT * FROM timescaledb_information.jobs;

SELECT remove_continuous_aggregate_policy('air_quality_summary_minute');
SELECT remove_continuous_aggregate_policy('light_summary_minute');
SELECT remove_continuous_aggregate_policy('motion_summary_minute');
SELECT remove_continuous_aggregate_policy('temperature_humidity_summary_minute');

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
       avg(humidity) AS avg_humidity
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
