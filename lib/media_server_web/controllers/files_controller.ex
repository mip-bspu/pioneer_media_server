defmodule MediaServerWeb.FilesController do
  use MediaServerWeb, :controller

  alias MediaServer.Files

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

    conn
    |> put_resp_content_type(MIME.from_path(path))
    |> send_file(200, path)

    # TODO: zip
  end
end
