defmodule MediaServer.Users do
  require Logger

  alias MediaServer.Repo
  alias MediaServer.Users
  alias MediaServer.Admin
  alias MediaServer.Tags

  def get_by_login(login),
    do:
      Repo.get_by(Users.User, login: login)
      |> Repo.preload(:tags)
      |> Repo.preload(:groups)

  def get_by_id(id),
    do:
      Repo.get_by(Users.User, id: id)
      |> Repo.preload(:tags)
      |> Repo.preload(:groups)

  def add_user(changeset) do
    %Users.User{}
    |> Users.User.changeset(%{})
    |> Repo.insert()
  end

  def update_user(old_user, changeset) do
    tags = changeset[:tags] && changeset[:tags] |> Tags.get_tags()
    groups = changeset[:groups] && changeset[:groups] |> Admin.get_groups()

    old_user
    |> Users.User.update_changeset(%{
      tags: tags || old_user.tags,
      groups: if(is_list(groups) && length(groups) > 0, do: groups, else: old_user.groups)
    })
    |> Repo.update()
  end
end
