defmodule MediaServerWeb.FilesController do
  use MediaServerWeb, :controller

  alias MediaServer.Files

  import FFmpex
  use FFmpex.Options

  def list(conn, %{"action_uuid" => uuid} = _params) do
    conn
    |> render("files.json", %{
      files: Files.get_files_by_action_uuid(uuid),
      action_uuid: uuid
    })
  end

  def content(conn, %{"uuid" => uuid} = _params) do
    file = Files.get_by_uuid(uuid)
    path = Files.file_path(file)

    # TODO: video preview
    case MIME.from_path(path) do
      "image/" <> format ->
        conn
        |> put_resp_content_type("images/" <> format)
        |> send_file(200, path)

      format ->
        IO.inspect(format)

        conn
        |> send_resp(:ok, "ok")
    end

    # TODO: zip
  end
end
