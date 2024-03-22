defmodule MediaServerWeb.FilesView do
  use MediaServerWeb, :view

  def normilize_files(files), do: Enum.map(files, fn file -> file_info(file) end)

  def file_info(file),
    do: %{
      id: file.id,
      name: file.name,
      extention: file.extention
    }
end
