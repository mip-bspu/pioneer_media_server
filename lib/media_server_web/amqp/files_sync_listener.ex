defmodule MediaServerWeb.AMQP.FilesSyncListener do
  require Logger
  use GenServer
  use AMQP

  alias MediaServer.Actions
  alias MediaServer.Files
  alias MediaServerWeb.AMQP.FilesSyncDownloader
  alias MediaServerWeb.Rpc.RpcClient

  @reconnect_interval 10000

  @name __MODULE__
  @connection_string Application.get_env(:pioneer_rpc, :connection_string)

  @queues Enum.map(
            [
              "months_state",
              "days_of_month_state",
              "rows_of_day_state",
              "get_by_uuid",
              "request_file_download",
              "load_chunk"
            ],
            &"#{Application.get_env(:media_server, :queue_tag)}.#{&1}"
          )

  def start_link(_state \\ []) do
    GenServer.start_link(@name, [], name: @name)
  end

  def init(_opts) do
    Logger.info("#{@name}: starting files sync listener")

    {:ok, connect()}
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
    {:noreply, connect()}
  end

  def handle_info(:try_to_connect, _state), do: {:noreply, connect()}

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
        Logger.error("#{@name}: Error serialize data: #{reason}")
    end
  end

  defp serialize(data), do: Poison.encode(data)

  defp deserialize(sdata), do: Poison.decode(sdata, keys: :atoms)

  def months_state(tags \\ []) do
    {:ok, rows} = Actions.months_state(tags)
    rows
  end

  def days_of_month_state(tags, date) do
    {:ok, rows} = Actions.days_of_month_state(tags, date)
    rows
  end

  def rows_of_day_state(tags, date) do
    {:ok, rows} = Actions.rows_of_day_state(tags, date)
    rows
  end

  def get_by_uuid(uuid) do
    try do
      Actions.get_by_uuid(uuid)
      |> Actions.action_normalize()
    rescue
      e ->
        Logger.error("#{@name}: Bad request by uuid: #{inspect(uuid)}, error: #{inspect(e)}")
        {:error, :bad_request}
    end
  end

  def request_file_download(dist_tag, uuid, action_uuid) do
    spawn(fn ->
      upload_chunk(dist_tag, uuid, action_uuid)
    end)

    :ok
  end

  defp upload_chunk(tag, uuid, action_uuid) do
    Files.upload_file(uuid, fn chunk ->
      RpcClient.upload_chunk(tag, chunk, action_uuid)
    end)
  end

  def load_chunk(chunk, action_uuid) do
    FilesSyncDownloader.load_chunk(chunk, action_uuid)
    :ok
  end
end
