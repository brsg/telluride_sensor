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

  def start_link do
    IO.puts("SensorEventConsumer.start_link")
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def channel_available(chan) do
    IO.puts("SensorEventConsumer.channel_available called with #{inspect chan}")
    GenServer.cast(__MODULE__, {:channel_available, chan})
  end

  ################################################################################
  # Server callbacks
  ################################################################################

  def init(_) do
    IO.puts("SensorEventConsumer.init(_)")
    SensorSimulator.Messaging.AMQPConnectionManager.request_channel(__MODULE__)
    {:ok, nil}
  end

  def handle_cast({:channel_available, channel}, _state) do
    # IO.puts("SensorEventConsumer.handle_cast({:channel_available, chan}, _state) called with #{inspect channel}");
    setup_queue(channel)
    # Limit unacknowledged messages to 10
    :ok = AMQP.Basic.qos(channel, prefetch_count: 10)
    # Register the GenServer process as a consumer
    {:ok, _consumer_tag} = AMQP.Basic.consume(channel, @message_queue)
    {:noreply, channel}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, channel) do
    # IO.puts("SensorEventConsumer.handle_info({:basic_consume_ok, %{consumer_tag: consumer_tag}}, channel)")
    {:noreply, channel}
  end

  # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, channel) do
  #   IO.puts("SensorEventConsumer.handle_info({:basic_cancel, %{consumer_tag: consumer_tag}}, channel)")
    {:stop, :normal, channel}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, channel) do
  #   IO.puts("SensorEventConsumer.handle_info({:basic_cancel_ok, %{consumer_tag: consumer_tag}}, channel)")
    {:noreply, channel}
  end

  def handle_info({:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered}}, channel) do
    # IO.puts("SensorEventConsumer.handle_info({:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered}}, channel)")
    # You might want to run payload consumption in separate Tasks in production
    consume(channel, tag, redelivered, payload)
    {:noreply, channel}
  end

  ################################################################################
  # Private
  ################################################################################

  defp setup_queue(channel) do
    IO.puts("SensorEventConsumer.setup_queue(#{inspect channel})")

    # Declare the error queue
    IO.puts("SensorEventConsumer.setup_queue - declaring queue '#{@error_queue}'")
    {:ok, _} = AMQP.Queue.declare(
      channel,
      @error_queue,
      durable: true
    )

    # Declare the message queue
    # Messages that cannot be delivered to any consumer in the
    # message queue will be routed to the error queue
    IO.puts("SensorEventConsumer.setup_queue - declaring queue '#{@message_queue}'")
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
    IO.puts("SensorEventConsumer.setup_queue - declaring exchange '#{@exchange}'")
    :ok = AMQP.Exchange.direct(channel, @exchange, durable: true)

    # Bind the main queue to the exchange
    IO.puts("SensorEventConsumer.setup_queue - binding queue '#{@message_queue}' to exchange '#{@exchange}'")
    :ok = AMQP.Queue.bind(channel, @message_queue, @exchange, routing_key: @routing_key)
  end

  defp consume(channel, tag, _redelivered, payload) do
    case JSON.decode(payload) do
      {:ok, event_info} ->
        IO.puts("SensorEventConsumer.consume received #{inspect event_info}")
        AMQP.Basic.ack(channel, tag)
      {:error, changeset} ->
        Basic.reject channel, tag, requeue: false
        IO.puts("error processing payload: #{inspect payload} with changeset: #{inspect changeset}")
      err ->
        Basic.reject channel, tag, requeue: false
        IO.puts("error #{inspect err} processing payload: #{inspect payload}")
        err
    end
  end

end
