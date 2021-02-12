# SensorSimulator

SensorSimulator generates (using a normal / Gaussian distribution) and publishes a stream of
simulated temperature sensor readings to a RabbitMQ queue `events`.

Any number of TemperatureSensor processes can be started, each of which is configured with: 
* line_id - the id of the manufacturing line on which the sensor is deployed
* device_id - the id of the device on the manufacturing line on which the sensor is located
* sensor_id - the id of the sensor
* mean - the mean temperature for the sensor's normal distribution of sensor readings
* variance - the variance for the sensor's normal distribution of sensor readings

Each sensor will emit a reading every 2 seconds of the following structure:
```
%{"device_id" => 100, "line_id" => 10, "reading" => 99.02638166702798, "sensor_id" => 1000, "timestamp" => "2021-02-12T01:18:51.838675Z"}
```

