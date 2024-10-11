defmodule MediaServerWeb.AMQP.InitService do
  require Logger
  use GenServer

  alias MediaServerWeb.Rpc.RpcClient
  alias MediaServer.Tags

  @interval_init 3000

  @name __MODULE__
  @my_queue_tag Application.get_env(:media_server, :queue_tag)
  @parent Application.get_env(:media_server, :queue_parent, nil)

  def start_link(_state), do: GenServer.start_link(@name, [], name: @name)

  def init(_state) do
    Logger.info("#{@name}: starting init service in #{@parent}")

    send(@name, {:init_in_parent, @parent})
    {:ok, :init}
  end

  def update_tags_in_parent() do
    if not is_nil(@parent) && not is_nil(GenServer.whereis(@name)) do
      if get_state() == :none do
        send(@name, {:init_in_parent, @parent})
        set_state(:init)
      end
    end
  end

  def get_state(), do: GenServer.call(@name, {:get_state})
  def set_state(state), do: GenServer.cast(@name, {:set_state, state})

  def handle_call({:get_state}, state), do: state
  def handle_cast({:set_state, state}, _), do: {:noreply, state}


  def handle_info({:init_in_parent, parent}, state) do
    spawn(fn -> init_in_parent(parent) end)

    {:noreply, state}
  end

  def init_in_parent(parent) do
    if parent != nil do
      case RpcClient.init_in_parent(
             parent,
             @my_queue_tag,
             Tags.get_all_my_tags() |> Tags.normalize_tags(@my_queue_tag)
           ) do
        {:ok, "ok"} ->
          Logger.debug("#{@name}: initialized in #{parent}")
          set_state(:none)

        error ->
          Logger.warning("#{@name}: Error initialization in #{parent}, reason: #{inspect(error)}")

          Process.send_after(@name, {:init_in_parent, parent}, @interval_init)
      end
    end
  end
end
