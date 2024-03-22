defmodule MediaServerWeb.ActionView do
  use MediaServerWeb, :view

  alias MediaServerWeb.TagsView
  alias MediaServerWeb.FilesView

  def render("action.json", %{action: action}), do: action_info(action)

  def action_info(action) do
    %{
      id: action.id,
      name: action.name,
      date_create: action.date_create,
      from: action.from,
      to: action.to,
      priority: action.priority,
      tags: TagsView.normilize_tags(action.tags),
      files: FilesView.normilize_files(action.files)
    }
  end
end
