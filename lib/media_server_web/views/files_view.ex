defmodule MediaServerWeb.FilesView do
  use MediaServerWeb, :view

  def normilize_files(files), do: Enum.map(files, fn file -> file_info(file) end)

  def file_info(file),
    do: %{
      id: file.uuid,
      name: file.name,
      extention: file.extention
    }
end
