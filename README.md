# SensorSimulator

SensorSimulator generates (using a normal / Gaussian distribution) and publishes a stream of
simulated temperature sensor readings to a RabbitMQ queue `events`.

## Sensors
Any number of Sensor processes can be started, each of which is configured with: 
* sensor_type - an atom such as :temperature, :viscosity, :pressure
* line_id - the id of the manufacturing line on which the sensor is deployed
* device_id - the id of the device on the manufacturing line on which the sensor is located
* sensor_id - the id of the sensor
* mean - the mean temperature for the sensor's normal distribution of sensor readings
* variance - the variance for the sensor's normal distribution of sensor readings

## Sensor Reading Events

Each sensor will emit a sensor reading event message every 2 seconds.

### Sensor Reading Event Schema
The structure of a sensor reading event is:
```
%{"device_id" => 100, "line_id" => 10, "reading" => 99.02638166702798, "sensor_id" => 1000, "timestamp" => "2021-02-12T01:18:51.838675Z"}
```

Sensor reading events are published to the `sensor_events` RabbitMQ exchange with a routing key of `sensor.reading` and messages with that routing key are routed to the `sensor_reading_queue` queue.

### RabbitMQ Configuration
| Exchange | Exchange Type | Routing Key | Queue |
| -------- | ---- | ----------- | ----- |
| sensor_events | direct | sensor.reading | sensor_readings_queue |

### RabbitMQ Producer
The module [SensorReadingProducer](lib/sensor_simulator/messaging/sensor_reading_producer.ex) is responsiblef for publishding sensor reading events.

## Sensor Health Events

SensorSimulator will also listen for incoming sensor health events on the `sensor_health_queue` in the `sensor_events` exchange.

### RabbitMQ Configuration
| Exchange | Exchange Type | Routing Key | Queue |
| -------- | ---- | ----------- | ----- |
| sensor_events | direct | sensor.health | sensor_health_queue |

### RabbitMQ Consumer
The module [SensorHealthProducer](lib/sensor_simulator/messaging/sensor_health_consumer.ex) is the consumer for sensor health events.

### Sensor Health Event Schema
A sensor health event is expected to have the following structure:

```
{
  max: 206.49300899515504, 
  mean: 205.0789023958593,
  min: 203.99665548109644,
  sensor_id: "a_sensor_id",
  total_reads: 41
}
```