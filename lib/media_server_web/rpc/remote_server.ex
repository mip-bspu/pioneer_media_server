defmodule MediaServerWeb.Rpc.RemoteServer do
  use PioneerRpc.PioneerRpcServer,
    queues: ["test"],
    connection_string: Application.get_env(:pioneer_rpc, :connection_string)
end
