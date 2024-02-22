defmodule MediaServerWeb.Rpc.RpcClient do
  use PioneerRpc.PioneerRpcClient,
    connection_string: Application.get_env(:pioneer_rpc, :connection_string)

  def months_state(tag, req_tags \\ []) do
    rpc({"#{tag}.months_state", [req_tags]})
  end
end
