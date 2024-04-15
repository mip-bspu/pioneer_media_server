defmodule MediaServerWeb.SessionView do
  use MediaServerWeb, :view

  alias MediaServerWeb.TagsView

  def render("authentication.json", %{authenticate: user}), do:
    %{
      login: user.login,
      tags: TagsView.normilize_tags(user.tags),
      groups: normilize_groups(user.groups)
    }

  def normilize_groups(groups), do:
    groups |> Enum.map(&(&1.name))
end
