defmodule SensorSimulator.Sensors.SensorEventProducer do

  alias __MODULE__

  @exchange       "sensor_events"
  @message_queue  "events"
  @error_queue    "errors"
  @routing_key    "sensor.event"

  ################################################################################
  # Client interface
  ################################################################################

  def start_link do
    IO.puts("SensorEventProducer.start_link")
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def channel_available(channel) do
    IO.puts("SensorEventProducer.channel_available called with #{inspect channel}")
    GenServer.cast(__MODULE__, {:channel_available, channel})
  end

  def publish(message) when is_map(message) do
    {:ok, json} = JSON.encode(message)
    SensorEventProducer.publish(json)
  end

  def publish(message) when is_binary(message) do
    IO.puts("SensorEventProducer.publish called with #{inspect message}")
    GenServer.call(__MODULE__, {:publish, message, @routing_key})
  end

  ################################################################################
  # Server callbacks
  ################################################################################

  def init(_) do
    IO.puts("SensorEventProducer.init(_)")
    SensorSimulator.Messaging.AMQPConnectionManager.request_channel(__MODULE__)
    {:ok, nil}
  end

  def handle_cast({:channel_available, channel}, _state) do
    IO.puts("SensorEventProducer.handle_cast({:channel_available, chan}, _state) called with #{inspect channel}");
    setup_queue(channel)
    {:noreply, channel}
  end

  def handle_call({:publish, message, @routing_key}, _from, channel) do
    AMQP.Basic.publish(
      channel,              #channel
      @exchange,            #exchange
      @routing_key,         #routing key
      message,              #payload
      persistent: true,     #options...
      content_type: "application/json"
    )
    {:reply, :ok, channel}
  end

  ################################################################################
  # Private
  ################################################################################

  defp setup_queue(channel) do
    IO.puts("SensorEventProducer.setup_queue(#{inspect channel})")

    # Declare the error queue
    IO.puts("SensorEventProducer.setup_queue - declaring queue '#{@error_queue}'")
    {:ok, _} = AMQP.Queue.declare(
      channel,
      @error_queue,
      durable: true
    )

    # Declare the message queue
    # Messages that cannot be delivered to any consumer in the
    # message queue will be routed to the error queue
    IO.puts("SensorEventProducer.setup_queue - declaring queue '#{@message_queue}'")
    {:ok, _} = AMQP.Queue.declare(
      channel,
      @message_queue,
      durable: true,
      arguments: [
        {"x-dead-letter-exchange", :longstr, ""},
        {"x-dead-letter-routing-key", :longstr, @error_queue}
      ]
    )

    # Declare an exchange of type direct
    IO.puts("SensorEventProducer.setup_queue - declaring exchange '#{@exchange}'")
    :ok = AMQP.Exchange.direct(channel, @exchange, durable: true)

    # Bind the main queue to the exchange
    IO.puts("SensorEventProducer.setup_queue - binding queue '#{@message_queue}' to exchange '#{@exchange}'")
    :ok = AMQP.Queue.bind(channel, @message_queue, @exchange, routing_key: @routing_key)
  end

end
