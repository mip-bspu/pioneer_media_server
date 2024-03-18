defmodule MediaServerWeb.TagsView do
  use MediaServerWeb, :view

  def render("tags.json", %{tags: tags} = _params) do
    normilize_tags(tags)
  end

  def tag_info(tag), do: %{name: tag.name, type: tag.type}

  def normilize_tags(tags), do: Enum.map(tags, fn tag -> tag_info(tag) end)
end
