defmodule SensorSimulator.Messaging.SensorEventConsumer do
  use GenServer
  use AMQP

  @exchange       "sensor_events"
  @message_queue  "events"
  @error_queue    "errors"
  @routing_key    "sensor.event"

  ################################################################################
  # Client interface
  ################################################################################

  @doc """
  Start a SensorEventConsumer process
  """
  def start_link do
    IO.puts("SensorEventConsumer.start_link")
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  @doc """
  Receive notification from the AMQP Connection Manager that a channel is available.
  """
  def channel_available(chan) do
    IO.puts("SensorEventConsumer.channel_available called with #{inspect chan}")
    GenServer.cast(__MODULE__, {:channel_available, chan})
  end

  ################################################################################
  # Server callbacks
  ################################################################################

  @doc """
  Initialize this process by requesting an AMQP channel from
  the AMQP Connection Manager
  """
  def init(_) do
    IO.puts("SensorEventConsumer.init(_)")
    SensorSimulator.Messaging.AMQPConnectionManager.request_channel(__MODULE__)
    {:ok, nil}
  end

  @doc """
  Receive notification from the AMQP Connection Manager that
  a channel is available

  ## Parameters

    - channel: the AMQP channel allocated by the Connection Manager
  """
  def handle_cast({:channel_available, channel}, _state) do
    setup_queue(channel)
    :ok = AMQP.Basic.qos(channel, prefetch_count: 10)
    {:ok, _consumer_tag} = AMQP.Basic.consume(channel, @message_queue)
    {:noreply, channel}
  end

  @doc """
  Receive confirmation from the broker that this process was registered as a consumer
  """
  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, channel) do
    {:noreply, channel}
  end

  @doc """
  Receive notification from the broker that this consumer was cancelled
  """
  def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, channel) do
    {:stop, :normal, channel}
  end

  @doc """
  Receive confirmation from the broker for a Basic.cancel
  """
  def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, channel) do
    {:noreply, channel}
  end

  @doc """
  Receive notification from the broker that a message has been delivered
  """
  def handle_info({:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered}}, channel) do
    consume(channel, tag, redelivered, payload)
    {:noreply, channel}
  end

  ################################################################################
  # Private
  ################################################################################

  @doc """
  Configure the AMQP consumer
  """
  defp setup_queue(channel) do

    # Declare an error queue
    {:ok, _} = AMQP.Queue.declare(
      channel,
      @error_queue,
      durable: true
    )

    # Declare a message queue
    {:ok, _} = AMQP.Queue.declare(
      channel,
      @message_queue,
      durable: true,
      arguments: [
        {"x-dead-letter-exchange", :longstr, ""},
        {"x-dead-letter-routing-key", :longstr, @error_queue}
      ]
    )

    # Declare a direct exchange
    :ok = AMQP.Exchange.direct(channel, @exchange, durable: true)

    # Bind the message queue to the exchange
    :ok = AMQP.Queue.bind(channel, @message_queue, @exchange, routing_key: @routing_key)
  end

  @doc """
  Consumer a delivered message and provide acknowledgement
  """
  defp consume(channel, delivery_tag, _redelivered, payload) do
    case JSON.decode(payload) do
      {:ok, event_info} ->
        IO.puts("SensorEventConsumer.consume received #{inspect event_info}")
        AMQP.Basic.ack(channel, delivery_tag)
      {:error, reason} ->
        Basic.reject channel, delivery_tag, requeue: false
        IO.puts("error '#{inspect reason}' processing payload: #{inspect payload}")
      err ->
        Basic.reject channel, delivery_tag, requeue: false
        IO.puts("error '#{inspect err}'' processing payload: #{inspect payload}")
        err
    end
  end

end
