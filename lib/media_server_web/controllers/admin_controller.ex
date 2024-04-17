defmodule MediaServerWeb.AdminController do
  use MediaServerWeb, :controller

  alias MediaServer.Admin

  plug MediaServerWeb.Plugs.Authentication, ["ADMIN"]

  def list_users(conn, _params \\ %{}) do
    conn
    |> put_status(200)
    |> render("users.json", %{users: Admin.get_users()})
  end

  def list_groups(conn, _params) do
    conn
    |> put_status(200)
    |> render("groups.json", %{groups: Admin.get_groups()})
  end

  def set_active(conn, %{"active" => val, "id" => user_id} = _params) do
    user_id = user_id |> String.to_integer()

    value =
      cond do
        val in ["0", "false", false] -> false
        val in ["1", "true", true] -> true
        true -> raise(BadRequestError, "Некоректное значение")
      end

    try do
      conn
      |> put_status(200)
      |> render("user.json", %{
        user: Admin.set_active_user!(user_id, value)
      })
    rescue
      reason -> raise(BadRequestError, "Некоректное значение: #{reason}")
    end
  end
end
