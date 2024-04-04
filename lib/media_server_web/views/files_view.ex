defmodule MediaServerWeb.FilesView do
  use MediaServerWeb, :view

  def render("files.json", %{files: files, action_uuid: uuid}), do:
    files |> Enum.map(&(file_info(&1) |> Map.put(:action, uuid)))

  def normilize_files(files), do: Enum.map(files, fn file -> file_info(file) end)

  def file_info(file),
    do: %{
      id: file.uuid,
      name: file.name,
      extention: file.extention
    }
end
