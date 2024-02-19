defmodule MediaServer.Content do

  alias MediaServer.Repo


  @dist_files "./files/"

  def file_path(filename), do: @dist_files <> filename
  def file_path(name, ext), do: @dist_files <> name <> ext

  def add_file!(name, %Plug.Upload{} = upload) do
    extention = Path.extname(upload.filename)

    upload!(upload.path, file_path(Ecto.UUID.generate(), extention))
  end

  def upload!(src_path, dist_path) do
    case File.cp(src_path, dist_path) do
      :ok ->
        init_hash = :crypto.hash_init(:sha256)

        File.stream!(dist_path, 2024)
        |> Enum.reduce(init_hash, fn(chunk, acc)->
          :crypto.hash_update(acc, chunk)
        end)
        |> :crypto.hash_final()
        |> Base.encode16(case: :lower)
      e ->
        raise(InternalServerError, "Не удалось загрузить файл, ошибка: #{inspect(e)}")
    end
  end
end
