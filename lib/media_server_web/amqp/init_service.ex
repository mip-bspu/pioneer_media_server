defmodule MediaServerWeb.AMQP.InitService do
  require Logger
  use GenServer

  alias MediaServerWeb.Rpc.RpcClient
  alias MediaServer.Tags

  @interval_init 3000

  @name __MODULE__
  @my_queue_tag Application.compile_env(:media_server, :queue_tag)
  @parent Application.compile_env(:media_server, :queue_parent, nil)

  def start_link(_state), do: GenServer.start_link(@name, [], name: @name)

  def init(_state) do
    Logger.info("#{@name}: starting init service in #{@parent}")

    send(@name, {:init_in_parent, @parent})
    {:ok, :state}
  end

  def handle_info({:init_in_parent, parent}, state) do
    spawn(fn -> init_in_parent(parent) end)

    {:noreply, state}
  end

  def init_in_parent(parent) do
    if parent != nil do
      case RpcClient.init_in_parent(
             parent,
             @my_queue_tag,
             Tags.get_all_my_tags()
           ) do
        {:ok, "ok"} ->
          Logger.debug("#{@name}: initialized in #{parent}")

        error ->
          Logger.warning("#{@name}: Error initialization in #{parent}, reason: #{inspect(error)}")

          Process.send_after(@name, {:init_in_parent, parent}, @interval_init)
      end
    end
  end
end
