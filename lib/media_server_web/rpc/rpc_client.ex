defmodule MediaServerWeb.Rpc.RpcClient do
  use PioneerRpc.PioneerRpcClient,
    connection_string: Application.get_env(:pioneer_rpc, :connection_string)

  def months_state(tag) do
    rpc({"#{tag}.months_state", []})
  end
end
