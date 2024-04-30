defmodule MediaServerWeb.Plugs.CheckTokenClient do
  import Plug.Conn
  import Phoenix.Controller

  alias MediaServer.Devices
  alias MediaServerWeb.ErrorView

  def init(opts \\ []), do: opts

  def call(conn, _opts) do
    token = conn
    |> get_req_header("__pioneer-token")
    |> get_token()

    if !is_nil(token) do
      conn
      |> check_device(Devices.get_by_token(token))
    else
      check_device(conn, nil)
    end
  end

  defp get_token([]), do: nil
  defp get_token([token]), do: token

  defp check_device(conn, nil),
  do:
    conn
    |> put_status(401)
    |> put_view(ErrorView)
    |> render("unauthorized.json", %{message: "Не верный токен"})
    |> halt()

  defp check_device(conn, _), do: conn
end
