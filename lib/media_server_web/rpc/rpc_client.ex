defmodule MediaServerWeb.Rpc.RpcClient do
  use PioneerRpc.PioneerRpcClient,
    connection_string: Application.get_env(:pioneer_rpc, :connection_string)

  @parents Application.compile_env(:media_server, :parents)

  def init_in_parent(parent, tags) do
    IO.puts(parent)
    rpc({parent, [tags]})
  end

  def ping_parent(tag, time) do
    try do
      case rpc({"#{tag}.ping", [time]}) do
        {:ok, %{value: "ok", time: reply_time}}->
          {:ok, reply_time}
        _->
          :error
      end
    rescue
      _ -> :error
    end
  end

  def months_state(tag, req_tags \\ []) do
    rpc({"#{tag}.months_state", [req_tags]})
  end
end
