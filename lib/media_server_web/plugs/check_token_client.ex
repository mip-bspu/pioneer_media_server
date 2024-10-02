defmodule MediaServerWeb.Plugs.CheckTokenClient do
  import Plug.Conn
  import Phoenix.Controller

  alias MediaServer.Devices

  def init(opts \\ []), do: opts

  def call(conn, _opts) do
    token = conn
    |> get_req_header("pioneer-token")
    |> get_token()

    if !is_nil(token) do
      conn
      |> check_device(Devices.get_by_token(token), token)
    else
      raise(UnauthorizedError, "Не верный токен")
    end
  end

  defp get_token([]), do: nil
  defp get_token([token]), do: token

  defp check_device(conn, device, token) do
    if is_nil(device) do
      raise(UnauthorizedError, "Не верный токен")
    end

    conn
    |> assign(:tags, Enum.map(device.tags, &(&1.name)))
    |> assign(:token, token)
  end
end
