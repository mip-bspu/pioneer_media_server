defmodule MediaServerWeb.AMQP.FilesSyncListener do
  require Logger
  use GenServer
  use AMQP

  alias MediaServer.Content
  alias MediaServerWeb.Rpc.RpcClient

  @name __MODULE__
  @reconnect_interval 10000

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

    case rabbitmq_connect() do
      {:ok, chan} ->
        Logger.debug("#{@name}: files sync listener connected to RabbitMQ")
        {:ok, chan}

      {:error, _message} ->
        Logger.warning("#{@name}: failed to connect RabbitMQ during init. Scheduling reconnect.")
        {:ok, :state}
    end
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
    # You might want to run payload consumption in separate Tasks in production
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
      Content.get_by_uuid!(uuid) # TODO: exception
      |> Content.parse_content()
    rescue
      e ->
        Logger.error("Bad request by uuid: #{inspect(uuid)}, error: #{inspect(e)}")
    end
  end

  def request_file_download(dist_tag, uuid) do
    spawn(fn->
      upload_chunk(dist_tag, uuid)
    end)

    :ok # TODO: if file exists
  end

  defp upload_chunk(tag, uuid) do
    Content.load_file(uuid, fn(chunk)->
      RpcClient.upload_chunk(tag, chunk)
    end)
  end

  def load_chunk(chunk) do
    IO.inspect(chunk)
    Content.upload_file(chunk)
    :ok
  end
end
