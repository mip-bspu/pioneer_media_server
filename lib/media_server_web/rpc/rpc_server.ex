defmodule MediaServerWeb.Rpc.RpcServer do
  use PioneerRpc.PioneerRpcServer,
    queues: [Application.get_env(:media_server, :queue_tag)],
    connection_string: Application.get_env(:pioneer_rpc, :connection_string)

  alias MediaServer.Content
  alias MediaServer.Tags

  @parent Application.compile_env(:media_server, :queue_parent)

  def urpc([child, tags]) do
    spawn(fn ->
      Tags.add_tags(child, tags)
    end)

    :ok
  end
end
