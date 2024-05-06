defmodule MediaServerWeb.ClientView do
  use MediaServerWeb, :view

  def render("content.json", %{content: content}), do: normalize_content(content)

  def normalize_content(content), do:
    Enum.map(content, fn(c)->
      %{
        uuid: c.uuid,
        ext: c.ext
      }
    end)
end
