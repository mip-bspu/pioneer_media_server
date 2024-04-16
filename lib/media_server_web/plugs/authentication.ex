defmodule MediaServer.Plugs.Authentication do
  import Plug.Conn

  alias MediaServer.Users
  alias MediaServerWeb.ErrorView

  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, list_groups) do
    user_id =
      conn
      |> fetch_session()
      |> get_session(:user_id)

    conn
    |> check_session(user_id)
    |> check_access_group(user_id, list_groups)
  end

  defp check_access_group(%{halted: true} = conn, _, _), do: conn

  defp check_access_group(conn, user_id, access_groups) do
    case Users.get_by_id(user_id) do
      nil ->
        error_unauthorized(conn)

      user ->
        user_groups = Enum.map(user.groups, & &1.name)

        if(is_any_groups(user_groups, access_groups), do: conn, else: error_unauthorized(conn))
    end
  end

  defp is_any_groups(user_groups, access_groups),
    do: length(user_groups -- access_groups) != length(user_groups)

  defp error_unauthorized(conn), do: check_session(conn, nil)

  defp check_session(conn, nil),
    do:
      conn
      |> put_status(401)
      |> put_view(ErrorView)
      |> render("unauthorized.json", %{message: "Не авторизован"})
      |> halt()

  defp check_session(conn, _), do: conn
end
