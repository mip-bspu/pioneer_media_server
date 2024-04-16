defmodule MediaServerWeb.SessionController do
  use MediaServerWeb, :controller

  alias MediaServer.Users
  alias MediaServerWeb.ErrorView

  def authenticate(conn, %{"login" => login, "password" => password} = _params) do
    case Users.get_by_login(login) do
      nil ->
        unauthorized_error(conn, "Не существующий пользователь")

      user ->
        if check_password?(user, password) do
          if user.active do
            conn
            |> fetch_session()
            |> clear_session()
            |> put_session(:user_id, user.id)
            |> put_status(200)
            |> render("authentication.json", %{authenticate: user})
          else
            unauthorized_error(conn, "Пользователь не активен")
          end
        else
          unauthorized_error(conn, "Не верный пароль")
        end
    end
  end

  def logout(conn, _params \\ %{}) do
    conn
    |> fetch_session()
    |> clear_session()
    |> send_resp(:ok, "ok")
  end

  defp check_password?(user, pwd), do: user.password == pwd

  defp unauthorized_error(conn, message),
    do:
      conn
      |> put_status(401)
      |> put_view(ErrorView)
      |> render("unauthorized.json", %{message: message})
end
