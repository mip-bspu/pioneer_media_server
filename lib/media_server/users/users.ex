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
    tags = changeset[:tags] && changeset[:tags] |> Tags.get_tags()
    groups = changeset[:groups] && changeset[:groups] |> Admin.get_groups()

    %Users.User{}
    |> Users.User.changeset(%{
      login: changeset[:login],
      password: changeset[:password],
      tags: tags,
      groups: if(is_list(groups) && length(groups) > 0, do: groups, else: Admin.get_groups(["USER"]))
    })
    |> Repo.insert()
  end

  def update_user(old_user, changeset) do
    tags = changeset[:tags] && changeset[:tags] |> Tags.get_tags()
    groups = changeset[:groups] && changeset[:groups] |> Admin.get_groups()

    old_user
    |> Users.User.update_changeset(%{
      tags: tags || [],
      groups: if(is_list(groups) && length(groups) > 0, do: groups, else: old_user.groups)
    })
    |> Repo.update()
  end

  def is_admin(%Users.User{} = user), do:
    not (user.groups
      |> Enum.find(fn g-> g.name == "ADMIN" end)
      |> is_nil)

  def get_tags_of_user_by_type(user, type) do
    user.tags
    |> Enum.filter(&(&1.type == type))
  end
end
