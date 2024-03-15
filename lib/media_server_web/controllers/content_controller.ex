defmodule MediaServerWeb.ContentController do
  use MediaServerWeb, :controller

  alias MediaServer.Content
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
end
