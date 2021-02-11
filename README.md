# SensorSimulator

SensorSimulator generates (using a normal / Gaussian distribution) and publishes a stream of simulated temperature sensor readings to a RabbitMQ topic.

Any number of TemperatureSensor processes can be started, each of which is configured with: 
* line_id - the id of the manufacturing line on which the sensor is deployed
* device_id - the id of the device on the manufacturing line on which the sensor is located
* sensor_id - the id of the sensor
* mean - a mean temperature for the sensor
* variance - a variance for use, in combination with `mean`, to generate sensor readings using a normal distribution

Each sensor will emit a reading every 2 seconds of the following structure:
```
{
  
}
```

