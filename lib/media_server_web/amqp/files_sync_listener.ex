defmodule MediaServerWeb.AMQP.FilesSyncListener do
  require Logger
  use GenServer
  use AMQP

  alias MediaServer.Content
  alias MediaServerWeb.Rpc.RpcClient

  @reconnect_interval 10000

  @name __MODULE__
  @connection_string Application.compile_env(:pioneer_rpc, :connection_string)

  @queues Enum.map(
            [
              "months_state",
              "days_of_month_state",
              "rows_of_day_state",
              "get_by_uuid",
              "request_file_download",
              "load_chunk"
            ],
            &"#{Application.compile_env(:media_server, :tag)}.#{&1}"
          )

  def start_link(_state \\ []) do
    GenServer.start_link(@name, [], name: @name)
  end

  def init(_opts) do
    Logger.info("#{@name}: starting files sync listener")

    connect()
    {:ok, :state}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, chan) do
    {:noreply, chan}
  end

  # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, chan) do
    {:stop, :normal, chan}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, chan) do
    {:noreply, chan}
  end

  def handle_info({:basic_deliver, payload, meta}, chan) do
    spawn(fn -> consume(chan, payload, meta) end)
    {:noreply, chan}
  end

  def handle_info({:DOWN, _, :process, _pid, _reason}, _state) do
    connect()
  end

  def handle_info(:try_to_connect, _state), do: connect()

  def connect() do
    case rabbitmq_connect() do
      {:ok, chan} ->
        Logger.debug("#{@name}: files sync listener connected to RabbitMQ")
        {:noreply, chan}

      {:error, _message} ->
        Logger.warning("#{@name}: failed to connect RabbitMQ during init. Scheduling reconnect.")

        Process.send_after(@name, :try_to_connect, @reconnect_interval)
        {:noreply, :not_connected}
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
        Logger.error("#{@name}: Error serialize data: #{reason}")
    end
  end

  defp serialize(data), do: Poison.encode(data)

  defp deserialize(sdata), do: Poison.decode(sdata, keys: :atoms)

  def months_state(tags \\ []) do
    {:ok, rows} = Content.months_state(tags)
    rows
  end

  def days_of_month_state(tags, date) do
    {:ok, rows} = Content.days_of_month_state(tags, date)
    rows
  end

  def rows_of_day_state(tags, date) do
    {:ok, rows} = Content.rows_of_day_state(tags, date)
    rows
  end

  def get_by_uuid(uuid) do
    try do
      Content.get_by_uuid!(uuid)
      |> Content.parse_content()
    rescue
      e ->
        Logger.error("#{@name}: Bad request by uuid: #{inspect(uuid)}, error: #{inspect(e)}")
        {:error, :bad_request}
    end
  end

  def request_file_download(dist_tag, uuid) do
    spawn(fn ->
      upload_chunk(dist_tag, uuid)
    end)

    :ok
  end

  defp upload_chunk(tag, uuid) do
    Content.load_file(uuid, fn chunk ->
      RpcClient.upload_chunk(tag, chunk)
    end)
  end

  def load_chunk(chunk) do
    Content.upload_file(chunk)
    :ok
  end
end
