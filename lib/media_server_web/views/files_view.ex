defmodule MediaServerWeb.FilesView do
  use MediaServerWeb, :view

  alias MediaServer.Files

  def render("files.json", %{files: files, action_uuid: uuid}),
    do: files |> Enum.map(&(file_info(&1) |> Map.put(:action, uuid)))

  def normalize_files(files), do: Enum.map(files, fn file -> file_info(file) end)

  def file_info(file),
    do: %{
      id: file.uuid,
      name: file.name,
      extention: file.extention,
      content_type: Files.file_path(file) |> MIME.from_path()
    }
end
