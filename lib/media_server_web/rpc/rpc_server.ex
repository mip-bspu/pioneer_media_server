defmodule MediaServerWeb.Rpc.RpcServer do
  require Logger

  use PioneerRpc.PioneerRpcServer,
    queues: [Application.get_env(:media_server, :queue_tag)],
    connection_string: Application.get_env(:pioneer_rpc, :connection_string)

  alias MediaServer.Tags

  def urpc([child, tags]) do
    try do
      Tags.add_tags!(child, tags)
    rescue
      e ->
        Logger.error(Exception.format(:error, e, __STACKTRACE__))
        :error
    else
      _ -> :ok
    end
  end
end
