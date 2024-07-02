defmodule MediaServerWeb.Plugs.Authentication do
  import Plug.Conn

  alias MediaServer.Users

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
        raise(UnauthorizedError, "Не авторизован")

      user ->
        user_groups = Enum.map(user.groups, & &1.name)

        if(is_any_groups(user_groups, access_groups),
          do: conn,
          else: raise(UnauthorizedError, "Не авторизован")
        )
    end
  end

  defp is_any_groups(user_groups, access_groups),
    do: length(user_groups -- access_groups) != length(user_groups)

  defp check_session(_conn, nil),
    do: raise(UnauthorizedError, "Не авторизован")

  defp check_session(conn, _), do: conn
end
