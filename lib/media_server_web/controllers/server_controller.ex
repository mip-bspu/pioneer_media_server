defmodule MediaServerWeb.ServerController do
  use MediaServerWeb, :controller

  alias MediaServer.Server

  plug MediaServerWeb.Plugs.Authentication, ["ADMIN", "USER", "VIEWER"]

  def setup(conn, _params) do
    conn
    |> put_status(200)
    |> render("setup.json", %{ setup: %{
      content: Server.get_formats_available()
    }})
  end
end
