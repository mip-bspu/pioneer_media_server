defmodule MediaServerWeb.AMQP.PingListener do
  require Logger
  use GenServer
  use AMQP

  alias MediaServer.Content

  @name __MODULE__
  @reconnect_interval 10000

  @connection_string Application.get_env(:pioneer_rpc, :connection_string)

  @queues Enum.map(
            ["ping"],
            &"#{Application.compile_env(:media_server, :tag)}.#{&1}"
          )

  def start_link(_state \\ []) do
    GenServer.start_link(@name, [], name: @name)
  end

  def init(_opts) do
    Logger.info("#{@name}: starting ping listener")

    case rabbitmq_connect() do
      {:ok, chan} ->
        Logger.debug("#{@name}: files sync listener connected to RabbitMQ")
        {:ok, chan}

      {:error, _message} ->
        Logger.warning("#{@name}: failed to connect RabbitMQ during init. Scheduling reconnect.")
        {:ok, :state}
    end
  end

  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, chan), do: {:noreply, chan}

  def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, chan), do: {:stop, :normal, chan}

  def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, chan), do: {:noreply, chan}

  def handle_info({:basic_deliver, payload, meta}, chan) do
    consume(chan, payload, meta)
    {:noreply, chan}
  end

  def rabbitmq_connect() do
    Logger.debug("Start connection...")
    connection_string = @connection_string

    case Connection.open(connection_string) do
      {:ok, conn} ->
        Logger.debug("#{@name}: listener connection '#{connection_string}'")
        {:ok, chan} = Channel.open(conn)

        setup(chan)

        {:ok, chan}

      {:error, message} ->
        Logger.warning("#{@name}: Error open connection: #{message}")
        {:error, message}
    end
  end

  defp setup(chan) do
    Basic.qos(chan, prefetch_count: 10)

    Enum.each(@queues, fn queue ->
      # exclusive: true
      Queue.declare(chan, queue, durable: true)
      Basic.consume(chan, queue, nil, no_ack: true)
    end)

    chan
  end

  defp consume(chan, payload, %{routing_key: routing_key, delivery_tag: tag} = meta) do
    [_tag, method] = String.split(routing_key, ".")

    {:ok, args} = deserialize(payload)

    data = apply(@name, String.to_atom(method), args)

    case serialize(data) do
      {:ok, sdata} ->
        AMQP.Basic.publish(
          chan,
          "",
          meta.reply_to,
          sdata,
          content_type: "application/json",
          correlation_id: meta.correlation_id
        )

      {:error, reason} ->
        Logger.error("Error serialize data: #{reason}")
    end
  end

  defp serialize(data), do: Poison.encode(data)

  defp deserialize(sdata), do: Poison.decode(sdata, keys: :atoms)


  def ping(time) do
    %{value: "ok", time: time}
  end
end
