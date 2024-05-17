defmodule MediaServerWeb.TagsController do
  use MediaServerWeb, :controller

  alias MediaServer.Tags
  alias MediaServerWeb.ErrorView

  plug MediaServerWeb.Plugs.Authentication, ["ADMIN"] when action in [:list]

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

  def create(conn, %{"name" => name, "type" => type} = _params) do
    case Tags.get_tag_by_name(name) do
      nil ->
        { :ok, tag } = Tags.create_tag(%{name: name, type: type})

        conn
        |> put_status(200)
        |> render("tag.json", %{tag: tag})
      _tag ->
        conn
        |> put_status(400)
        |> put_view(ErrorView)
        |> render("bad_request.json", %{message: "Такой тэг уже существует"})
    end
  end
end
