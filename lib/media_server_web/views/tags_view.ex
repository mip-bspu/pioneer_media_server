defmodule MediaServerWeb.TagsView do
  use MediaServerWeb, :view

  def render("tags.json", %{tags: tags} = _params) do
    normalize_tags(tags)
  end

  def render("tag.json", %{tag: tag} = _params), do: tag_info(tag)

  def tag_info(tag), do: %{id: tag.id, name: tag.name, type: tag.type, owner: tag.owner}

  def normalize_tags(tags), do: Enum.map(tags, fn tag -> tag_info(tag) end)
end
