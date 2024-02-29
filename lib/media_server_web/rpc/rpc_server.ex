defmodule MediaServerWeb.Rpc.RpcServer do
  use PioneerRpc.PioneerRpcServer,
    queues: [Application.get_env(:media_server, :queue_tag)],
    connection_string: Application.get_env(:pioneer_rpc, :connection_string)

  alias MediaServerWeb.AMQP.InitService
  alias MediaServer.Content

  @parent Application.compile_env(:media_server, :queue_parent)

  def urpc([child, tags]) do
    spawn(fn ->
      Content.add_tags(child, tags)
    end)

    :ok
  end
end
