defmodule MediaServerWeb.AMQP.PingListener do
  require Logger
  use GenServer
  use AMQP

  @name __MODULE__
  @reconnect_interval 10000

  @connection_string Application.compile_env(:pioneer_rpc, :connection_string)

  @queues Enum.map(
            ["ping"],
            &"#{Application.compile_env(:media_server, :queue_tag)}.#{&1}"
          )

  def start_link(_state \\ []) do
    GenServer.start_link(@name, [], name: @name)
  end

  def init(_opts) do
    Logger.info("#{@name}: starting ping listener")

    {:ok, connect()}
  end

  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, chan), do: {:noreply, chan}

  def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, chan),
    do: {:stop, :normal, chan}

  def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, chan), do: {:noreply, chan}

  def handle_info({:basic_deliver, payload, meta}, chan) do
    spawn(fn -> consume(chan, payload, meta) end)
    {:noreply, chan}
  end

  def handle_info(:try_to_connect, _state) do
    {:noreply, connect()}
  end

  def handle_info({:DOWN, _, :process, _pid, _reason}, _state) do
    {:noreply, connect()}
  end

  def connect() do
    case rabbitmq_connect() do
      {:ok, chan} ->
        Logger.debug("#{@name}: files sync listener connected to RabbitMQ")
        chan

      {:error, _message} ->
        Logger.warning("#{@name}: failed to connect RabbitMQ during init. Scheduling reconnect.")

        Process.send_after(@name, :try_to_connect, @reconnect_interval)
        :not_connected
    end
  end

  def rabbitmq_connect() do
    Logger.debug("Start connection...")

    case Connection.open(@connection_string) do
      {:ok, conn} ->
        Logger.debug("#{@name}: listener connection '#{@connection_string}'")

        Process.monitor(conn.pid)

        case Channel.open(conn) do
          {:ok, chan} ->
            setup(chan)

            {:ok, chan}

          {:error, reason} ->
            Logger.warning("#{@name}: Error open channel: #{reason}")
            {:error, reason}
        end

      {:error, reason} ->
        Logger.warning("#{@name}: Error open connection: #{reason}")
        {:error, reason}
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

  defp consume(:not_connected, _payload, _meta),
    do:
      Logger.warning("#{@name}: files sync doesn't consume because isn't connected into rabbitMQ")

  defp consume(chan, payload, %{routing_key: routing_key, delivery_tag: _tag} = meta) do
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
