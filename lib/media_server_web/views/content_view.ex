defmodule MediaServerWeb.ContentView do
  use MediaServerWeb, :view

  alias MediaServer.Content
  alias MediaServerWeb.TagsView

  def render("data_file.json", %{data_file: file}), do: content_info(file)

  def render("content.json", %{content: content}) do
    %{
      content: Enum.map(content[:content], &content_info(&1)),
      total_items: content[:total_items],
      page_size: content[:page_size],
      page: content[:page]
    }
  end

  defp content_info(file),
    do: %{
      id: file.id,
      date_create: file.date_create,
      from: file.from,
      to: file.to,
      name: file.name,
      extention: file.extention,
      tags: TagsView.normilize_tags(file.tags)
    }
end
