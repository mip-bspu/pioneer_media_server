defmodule MediaServerWeb.ActionView do
  use MediaServerWeb, :view

  alias MediaServerWeb.TagsView
  alias MediaServerWeb.FilesView

  def render("actions.json", %{actions: actions}),
    do: %{
      actions: actions[:actions] |> Enum.map(&action_info(&1)),
      page: actions[:page],
      page_size: actions[:page_size],
      total_items: actions[:total_items]
    }

  def render("action.json", %{action: action}), do: action_info(action)

  def action_info(action) do
    %{
      id: action.uuid,
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
