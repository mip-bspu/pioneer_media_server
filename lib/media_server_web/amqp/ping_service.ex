defmodule MediaServerWeb.AMQP.PingService do
  require Logger
  use GenServer

  alias MediaServerWeb.Rpc.RpcClient

  @name __MODULE__
  @parents Application.compile_env(:media_server, :parents, [])

  @interval_ping 2000


  def get_ping(tag) do
    GenServer.call(@name, {:get_ping, tag})
  end

  def start_link(_state), do: GenServer.start_link(@name, %{}, name: @name)

  def init(state) do
    Logger.info("#{@name}: starting ping service")

    new_state =
      @parents
      |> Enum.reduce( state, &(Map.put(&2, &1, nil)) )

    Process.send_after(@name, :ping, @interval_ping)
    {:ok, new_state}
  end

  def handle_call({:get_ping, tag}, _from, state) do
     {:reply, state[tag], state}
  end

  def handle_info(:ping, state) do
    Enum.each( Map.keys(state), fn(key)->
      spawn(fn-> ping_parent(key) end)
    end)

    Process.send_after(@name, :ping, @interval_ping)
    {:noreply, state}
  end

  def handle_info({:set_ping, tag, time}, state) do
    {:noreply, %{state | tag=>time}}
  end

  def ping_parent(tag) do
    case RpcClient.ping_parent(tag, :os.system_time(:millisecond)) do
      {:ok,  reply_time} ->
        send(@name, {:set_ping, tag, :os.system_time(:millisecond)-reply_time})
      :error ->
        send(@name, {:set_ping, tag, nil})
    end
  end

end
