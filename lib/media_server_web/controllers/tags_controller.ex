defmodule MediaServerWeb.TagsController do
  use MediaServerWeb, :controller

  alias MediaServer.Tags

  def list(conn, params) do
    by_types =
      (params["types"] && params["types"] |> String.split([",", ", "], trim: true)) || :none

    by_tags =
      (params["tags"] && params["tags"] |> String.split([",", ", "], trim: true)) || :none

    tags = Tags.get_filtered_tags(%{list_tags: by_tags, list_types: by_types})

    conn
    |> put_status(200)
    |> render("tags.json", %{tags: tags})
  end
end
