defmodule MediaServerWeb.SessionView do
  use MediaServerWeb, :view

  alias MediaServerWeb.TagsView

  def render("authentication.json", %{authenticate: user}),
    do: %{
      login: user.login,
      tags: TagsView.normalize_tags(user.tags),
      groups: normalize_groups(user.groups)
    }

  def normalize_groups(groups), do: groups |> Enum.map(& &1.name)
end
