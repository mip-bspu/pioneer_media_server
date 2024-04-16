defmodule MediaServer.Admin do
  require Logger

  alias MediaServer.Repo
  alias MediaServer.Users

  import Ecto.Query

  def get_users() do
    from(u in Users.User, join: g in assoc(u, :groups), where: "ADMIN" != g.name)
    |> Repo.all()
    |> Repo.preload(:tags)
    |> Repo.preload(:groups)
  end
end
