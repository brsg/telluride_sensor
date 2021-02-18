# TellurideSensor

TellurideSensor collaborates with [TelluridePipelime](https://github.com/brsg/telluride_pipeline) and [TellurideUI](https://github.com/brsg/telluride_ui) to provide an example of a [Broadway](https://github.com/dashbitco/broadway) pipeline consuming a stream of simulated IoT sensor reading messages from a `RabbitMQ` queue, in batches, computing some simple aggregate metrics over the stream of messages, and then publishlishing those metrics in a batch-oriented way to a queue on `RabbitMQ` by way of the [BroadwayRabbitMQ](https://github.com/dashbitco/broadway_rabbitmq) producer.  The point of this example is not the domain, which is contrived, but the mechanics of `Broadway` and Rabbit MQ working together.

The TellurideSensor application generates and publishes a stream of simulated IoT sensor reading events.

The objective of TellurideSensor is to generate a volume-configuable stream of data for testing and simulation. The realism and fidelity of the generated data to actual IoT sensor reading was really not a primary concern, and the generated data is admittedly contrived.

Sensor readings are randomly generated, using a normal / Gaussian distribution, from `mean` and `variance` values that are supplied when a sensor is created.

TellurideSensor also listens for an incoming stream of sensor health events. A sensor health event relates to a specific sensor and records the min, max and average sensor readings that have been seen as of particular point in time. The idea is that some process might be listening for sensor reading events and computing, and then feeding back, some "analytics" about the sensors - in this case the expectation is some simple aggregate analytics for a sensor (min, max and average sensor reading).

RabbitMQ is used to publish and consume sensor events.

To run TellurideSensor, see the [Getting Started](#getting-started) section below.

## Sensors

Any number of Sensor processes can be started, each of which is configured with: 
* sensor_type - an atom such as :temperature, :viscosity, :pressure, :proximity, :turbidity, :level
* line_id - the id of the hypthetical manufacturing line on which the sensor is deployed
* device_id - the id of the device on the manufacturing line on which the sensor is located
* sensor_id - the id of the sensor on the device
* mean - the mean temperature for the sensor's normal distribution of sensor readings
* variance - the variance for the sensor's normal distribution of sensor readings

## Sensor Reading Events

Each sensor will emit a sensor reading event message every 2 seconds.

#### Sensor Reading Event Schema

The structure of a sensor reading event is:
```
{
  "device_id" : 100, 
  "line_id" : 10, 
  "reading" : 99.02638166702798, 
  "sensor_id" : 1000, 
  "timestamp" : "2021-02-12T01:18:51.838675Z"
}
```

Sensor reading events are published to the `sensor_events` RabbitMQ exchange with a routing key of `sensor.reading`, which messages will be routed to the `sensor_reading_queue` queue.

#### RabbitMQ Configuration

| Exchange | Exchange Type | Routing Key | Queue |
| -------- | ---- | ----------- | ----- |
| sensor_events | direct | sensor.reading | sensor_readings_queue |

#### RabbitMQ Producer

The module [SensorReadingProducer](lib/telluride_sensor/messaging/sensor_reading_producer.ex) is responsible for publishing sensor reading events.

## Sensor Health Events

TellurideSensor will also listen for incoming sensor health events on the `sensor_health_queue` in the `sensor_events` exchange.

#### RabbitMQ Configuration

| Exchange | Exchange Type | Routing Key | Queue |
| -------- | ---- | ----------- | ----- |
| sensor_events | direct | sensor.health | sensor_health_queue |

#### RabbitMQ Consumer

The module [SensorHealthConsumer](lib/telluride_sensor/messaging/sensor_health_consumer.ex) is responsible for consuming sensor health events.

#### Sensor Health Event Schema

A sensor health event is expected to have the following structure:

```
{
  "max" : 206.49300899515504, 
  "mean" : 205.0789023958593,
  "min ": 203.99665548109644,
  "sensor_id" : "a_sensor_id",
  "total_reads" : 41
}
```

## <a name="getting-started"></a> Getting Started

1. Start RabbitMQ

    $ cd telluride_sensor
    $ bin/rmq-up.sh   (or docker-compose up [-d])

2. Start the TellurideSensor application

    $ cd telluride_sensor
    $ iex -S mix

