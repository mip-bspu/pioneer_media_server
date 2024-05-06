defmodule MediaServerWeb.AdminView do
  use MediaServerWeb, :view

  alias MediaServerWeb.TagsView

  def render("users.json", %{users: users}), do: users |> Enum.map(&normalize_user(&1))

  def render("user.json", %{user: user}), do: normalize_user(user)

  def render("groups.json", %{groups: groups}), do: normalize_groups(groups)

  def normalize_user(user),
    do: %{
      id: user.id,
      login: user.login,
      active: user.active,
      tags: TagsView.normalize_tags(user.tags),
      groups: normalize_groups(user.groups)
    }

  def normalize_groups(groups), do: groups |> Enum.map(& &1.name)

  def normalize_devices(devices),
    do:
      devices
      |> Enum.map(fn device ->
        %{
          description: device.description,
          token: device.token,
          tags: TagsView.normalize_tags(device.tags),
        }
      end)
end
