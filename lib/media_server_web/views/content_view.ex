defmodule MediaServerWeb.ContentView do
  use MediaServerWeb, :view

  alias MediaServer.Content

  def render("data_file.json", %{data_file: file}) do
    %{
      id: file.id,
      date_create: file.date_create,
      from: file.from,
      to: file.to,
      name:  file.name,
      tags: normilize_tags(file.tags)
    }
  end


  defp normilize_tags(tags), do: Enum.map(tags, fn(tag)->parse_tag(tag) end)

  defp parse_tag(tag), do: %{name: tag.name, type: tag.type}
end
