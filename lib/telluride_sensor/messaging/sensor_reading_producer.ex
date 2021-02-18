defmodule TellurideSensor.Messaging.SensorEventProducer do
  use GenServer

  alias __MODULE__
  alias TellurideSensor.Messaging.AMQPConnectionManager
  alias TellurideSensor.Messaging.SensorReadingQueue

  ################################################################################
  # Client interface
  ################################################################################

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, [name: __MODULE__])
  end

  def publish(message) when is_map(message) do
    {:ok, json} = JSON.encode(message)
    SensorEventProducer.publish(json)
  end

  def publish(message) when is_binary(message) do
    GenServer.call(__MODULE__, {:publish, message, @routing_key})
  end

  ################################################################################
  # AMQPConnectionManager callbacks
  ################################################################################

  def channel_available(channel) do
    GenServer.cast(__MODULE__, {:channel_available, channel})
  end

  ################################################################################
  # GenServer callbacks
  ################################################################################

  @impl true
  def init(_init_arg) do
    AMQPConnectionManager.request_channel(__MODULE__)
    {:ok, nil}
  end

  @impl true
  def handle_cast({:channel_available, channel}, _state) do
    :ok = SensorReadingQueue.configure_producer(channel)
    {:noreply, channel}
  end

  @impl true
  def handle_call({:publish, message, @routing_key}, _from, channel) do
    AMQP.Basic.publish(
      channel,                            #channel
      SensorReadingQueue.exchange,        #exchange
      SensorReadingQueue.msg_routing_key, #routing key
      message,                            #payload
      persistent: true,                   #options...
      content_type: "application/json"
    )
    {:reply, :ok, channel}
  end

end
