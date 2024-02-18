defmodule MediaServerWeb.Rpc.ParentClient do
  use PioneerRpc.PioneerRpcClient,
    connection_string: Application.get_env(:pioneer_rpc, :connection_string)
end
