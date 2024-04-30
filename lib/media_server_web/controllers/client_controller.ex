defmodule MediaServerWeb.ClientController do
  use MediaServerWeb, :controller

  alias Plug.Conn
  alias MediaServer.Files
  alias MediaServer.Devices
  alias MediaServerWeb.ErrorView

  plug MediaServerWeb.Plugs.CheckTokenClient, [] when action in [:schedule]

  def initialize(conn, %{ "token" => token } = _params) do
    Devices.get_by_token(token)
    |> case do
      nil ->
        conn
        |> put_status(401)
        |> put_view(ErrorView)
        |> render("unauthorized.json", %{message: "Неверный токен"})
        |> halt()
      _device ->

        conn
        |> put_status(200)
        |> json(%{message: "ok"})
    end
  end

  def schedule(conn, params) do

    conn
    |> send_resp(:ok, "ok")
  end

end
