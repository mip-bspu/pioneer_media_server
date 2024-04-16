defmodule MediaServerWeb.AdminController do
  use MediaServerWeb, :controller

  alias MediaServer.Admin

  plug MediaServer.Plugs.Authentication, ["ADMIN"]

  def list_users(conn, params \\ %{}) do
    conn
    |> put_status(200)
    |> render("users.json", %{users: Admin.get_users()})
  end
end
