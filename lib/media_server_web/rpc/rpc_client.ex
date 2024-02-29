defmodule MediaServerWeb.Rpc.RpcClient do
  use PioneerRpc.PioneerRpcClient,
    connection_string: Application.get_env(:pioneer_rpc, :connection_string)

  def init_in_parent(parent, my_tag, tags) do
    rpc({parent, [my_tag, tags]})
  end

  def ping_parent(tag, time) do
    try do
      case rpc({"#{tag}.ping", [time]}) do
        {:ok, %{value: "ok", time: reply_time}} ->
          {:ok, reply_time}

        _ ->
          :error
      end
    rescue
      _ -> :error
    end
  end

  def months_state(tag, request_tags \\ []) do
    rpc({"#{tag}.months_state", [request_tags]})
  end

  def days_of_month_state(tag, request_tags, date) do
    rpc({"#{tag}.days_of_month_state", [request_tags, date]})
  end

  def rows_of_day_state(tag, request_tags, date) do
    rpc({"#{tag}.rows_of_day_state", [request_tags, date]})
  end

  def get_by_uuid(tag, uuid) do
    rpc({"#{tag}.get_by_uuid", [uuid]})
  end

  def request_file_download(tag, my_tag, uuid) do
    rpc({"#{tag}.request_file_download", [my_tag, uuid]})
  end

  def upload_chunk(tag, chunk) do
    rpc({"#{tag}.load_chunk", [chunk]})
  end
end
