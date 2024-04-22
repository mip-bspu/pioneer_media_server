defmodule MediaServerWeb.AdminView do
  use MediaServerWeb, :view

  alias MediaServerWeb.TagsView

  def render("users.json", %{users: users}), do: users |> Enum.map(&normilize_user(&1))

  def render("user.json", %{user: user}), do: normilize_user(user)

  def render("groups.json", %{groups: groups}), do: normilize_groups(groups)

  def normilize_user(user),
    do: %{
      id: user.id,
      login: user.login,
      active: user.active,
      tags: TagsView.normilize_tags(user.tags),
      groups: normilize_groups(user.groups)
    }

  def normilize_groups(groups), do: groups |> Enum.map(& &1.name)
end
