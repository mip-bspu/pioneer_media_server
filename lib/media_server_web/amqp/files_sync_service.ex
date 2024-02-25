defmodule MediaServerWeb.AMQP.FilesSyncService do
  require Logger
  use GenServer
  use AMQP

  alias MediaServerWeb.Rpc.RpcClient
  alias MediaServer.Content

  @name __MODULE__
  @check_interval 1000

  @parents Application.compile_env(:media_server, :parents)
  @my_tag Application.compile_env(:media_server, :tag)

  def start_link(_state \\ []) do
    GenServer.start_link(@name, [], name: @name)
  end

  def init(_opts) do
    Logger.info("#{@name}: starting files sync service")

    Process.send_after(@name, :check_content, @check_interval)
    {:ok, :state}
  end

  def handle_info(:check_content, state) do
    @parents
    |> Enum.each(fn tag ->
      spawn(fn ->
        {:ok, remote_state} = RpcClient.months_state(tag, [@my_tag])
        {:ok, local_state} = Content.months_state([])

        IO.inspect(remote_state)
        IO.inspect(local_state)
      end)
    end)

    {:noreply, state}
  end
end
