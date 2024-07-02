defmodule MediaServerWeb.TagsController do
  use MediaServerWeb, :controller

  alias MediaServer.Tags

  plug MediaServerWeb.Plugs.Authentication, ["ADMIN"] when action in [:list_all, :create, :delete]
  plug MediaServerWeb.Plugs.Authentication, ["ADMIN", "USER"] when action in [:list]

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

  def list_all(conn, params) do
    conn
    |> put_status(200)
    |> render("tags.json", %{tags: Tags.get_all_tags()})
  end

  def create(conn, %{"name" => name, "type" => type} = _params) do
    case Tags.get_tag_by_name(name) do
      nil ->
        Tags.create_tag(%{name: name, type: type})
        |> case do
          {:ok, tag} ->
            conn
            |> put_status(200)
            |> render("tag.json", %{tag: tag})

          {:error, _reason} ->
            raise(BadRequestError, "Неверные данные")
        end

      _tag ->
        raise(BadRequestError, "Такой тэг уже существует")

    end
  end

  def delete(conn, %{"id" => id} = _params) do
    Tags.get_tag_by_id(id)
    |> case do
      nil ->
        raise(BadRequestError, "Тэг не найден")

      tag ->
        Tags.delete_tag!(tag)

        conn
        |> send_resp(:ok, "ok")
    end
  end
end
