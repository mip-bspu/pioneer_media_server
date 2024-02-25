defmodule MediaServerWeb.AMQP.InitService do
  require Logger
  use GenServer

  alias MediaServerWeb.AMQP.PingService
  alias MediaServerWeb.Rpc.RpcClient

  @name __MODULE__
  @parents Application.compile_env(:media_server, :parents, [])

  @interval_init 3000

  def reinit_in_parent(), do: GenServer.cast(@name, :init_in_parent)

  def start_link(_state), do: GenServer.start_link(@name, [], name: @name)

  def init(_state) do
    Logger.info("#{@name}: starting init service in parents: #{inspect(@parents)}")

    Process.send_after(@name, :init_in_parent, @interval_init)
    {:ok, :state}
  end


  def handle_cast(:init_in_parent, state) do
    Enum.each(@parents, fn(parent)->
      spawn(fn->init_in_parent(parent) end)
    end)
    {:noreply, state}
  end

  def handle_info(:init_in_parent, state) do
    Enum.each(@parents, fn(parent)->
      spawn(fn->init_in_parent(parent) end)
    end)
    {:noreply, state}
  end

  def handle_info({:init_in_parent, parent}, state) do
    spawn(fn->init_in_parent(parent) end)
    {:noreply, state}
  end

  def init_in_parent(parent) do
    if is_integer(PingService.get_ping(parent)) do
      case RpcClient.init_in_parent(parent, ["school", "section1"]) do
        {:ok, "ok"}->
          Logger.debug("#{@name}: initialized in #{parent}")
        error->
          Logger.warning("#{@name}: Error initialization in #{parent}, reason: #{inspect(error)}")

          Process.send_after(@name, {:init_in_parent, parent}, @interval_init)
      end
    else
      Process.send_after(@name, {:init_in_parent, parent}, @interval_init)
    end
  end
end
