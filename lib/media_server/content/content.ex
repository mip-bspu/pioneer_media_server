defmodule MediaServer.Content do

  alias MediaServer.Repo
  alias MediaServer.Content
  alias MediaServer.Util.TimeUtil


  @dist_files "./files/"

  def file_path(filename), do: @dist_files <> filename
  def file_path(name, ext), do: @dist_files <> name <> ext

  def add_file!(name, %Plug.Upload{} = upload) do
    Repo.transaction(fn->
      extention = Path.extname(upload.filename)

      file = %Content.File{}
      |> Content.File.changeset(%{
        uuid: Ecto.UUID.generate(),
        date_create: TimeUtil.current_date_time(),
        extention: extention,
        name: name
      }) |> Repo.insert!()

      file
      |> Content.File.changeset(%{
        check_sum: upload!(upload.path, file_path(file.uuid, file.extention))
      }) |> Repo.update!()
    end)
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
