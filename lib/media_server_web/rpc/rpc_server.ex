defmodule MediaServerWeb.Rpc.RpcServer do
  use PioneerRpc.PioneerRpcServer,
    queues: [ Application.get_env(:media_server, :tag) ],
    connection_string: Application.get_env(:pioneer_rpc, :connection_string)

  alias MediaServerWeb.AMQP.InitService
  alias MediaServer.NodeServer

  @parents Application.compile_env(:media_server, :tag)

  def urpc([tags]) do
    spawn(fn->
      NodeServer.add_nodes(
        Enum.map(tags, &(%{name: &1}))
      )

      if @parents != [] do
        InitService.reinit_in_parent()
      end
    end)
    :ok
  end
end
