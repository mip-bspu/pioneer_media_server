defmodule MediaServerWeb.AMQP.PingService do
  require Logger
  use GenServer

  alias MediaServerWeb.Rpc.RpcClient

  @name __MODULE__
  @parent Application.compile_env(:media_server, :queue_parent)

  @interval_ping 2000

  def get_ping(tag) do
    GenServer.call(@name, {:get_ping, tag})
  end

  def start_link(_state), do: GenServer.start_link(@name, %{ping: nil}, name: @name)

  def init(state) do
    Logger.info("#{@name}: starting ping service")

    Process.send_after(@name, :ping, @interval_ping)
    {:ok, state}
  end

  def handle_call({:get_ping, tag}, _from, state) do
    {:reply, state[tag], state}
  end

  def handle_info(:ping, state) do
    spawn(fn -> ping_parent(@parent) end)

    Process.send_after(@name, :ping, @interval_ping)
    {:noreply, state}
  end

  def handle_info({:set_ping, time}, _state) do
    {:noreply, %{ping: time}}
  end

  def ping_parent(tag) do
    case RpcClient.ping_parent(tag, :os.system_time(:millisecond)) do
      {:ok, reply_time} ->
        send(@name, {:set_ping, :os.system_time(:millisecond) - reply_time})

      :error ->
        send(@name, {:set_ping, nil})
    end
  end
end
