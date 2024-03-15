defmodule MediaServerWeb.ContentController do
  use MediaServerWeb, :controller

  alias MediaServer.Content
  alias MediaServer.Util.FormatUtil

  # TODO: check format files
  def create(
        conn,
        %{
          "name" => name,
          "tags" => tags,
          "from" => from,
          "to" => to,
          "file" => %Plug.Upload{} = upload
        } = _res
      ) do
    case Poison.decode(tags) do
      {:ok, tags} ->
        {:ok, file} = Content.add_file!(%{name: name, from: from, to: to, tags: tags}, upload)

        conn
        |> put_status(200)
        |> render("data_file.json", %{data_file: file})

      {:error, reason} ->
        raise(BadRequestError, "Неверные данные #{inspect(reason)}")
    end
  end

  def update(
        conn,
        %{
          "id" => id,
          "name" => name,
          "tags" => tags,
          "from" => from,
          "to" => to
        } = params
      ) do
    case Poison.decode(tags) do
      {:ok, tags} ->
        {id, ""} = Integer.parse(id)

        {:ok, file} =
          Content.update_file!(
            %{id: id, name: name, from: from, to: to, tags: tags},
            params["file"] || nil
          )

        conn
        |> put_status(200)
        |> render("data_file.json", %{data_file: file})

      {:error, reason} ->
        raise(BadRequestError, "Неверные данные #{inspect(reason)}")
    end
  end

  def delete(conn, %{"id" => id} = _params) do
    file = Content.delete_content!(id)

    conn
    |> put_status(200)
    |> render("data_file.json", %{data_file: file})
  end

  def list(conn, params) do
    page = Access.get(params, "page", 0) |> FormatUtil.to_integer()
    page_size = Access.get(params, "page_size", 20) |> FormatUtil.to_integer()

    tags =
      Access.get(params, "tags", "")
      |> String.split([",", ", "], trim: true)

    {total, list} = Content.list_content(page, page_size, tags)

    conn
    |> put_status(200)
    |> render("content.json", %{
      content: %{
        content: list,
        total_items: total,
        page: page,
        page_size: page_size
      }
    })
  end
end
