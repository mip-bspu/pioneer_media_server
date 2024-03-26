defmodule MediaServer.Files do
  require Logger

  alias MediaServer.Repo
  alias MediaServer.Files
  alias MediaServer.Tags
  alias MediaServer.Util.TimeUtil
  alias MediaServer.Util.QueryUtil

  import Ecto.Query

  @dist_files Application.compile_env(:media_server, :dist_content, "./files/")
  @chunk_size 2000

  def get_by_uuid(uuid) do
    Repo.get_by(Files.File, uuid: uuid)
  end

  def add_file_data!(data) do
    %Files.File{}
    |> Files.File.changeset(%{
      uuid: data[:uuid] || Ecto.UUID.generate(),
      check_sum: data[:check_sum] || nil,
      extention: data[:extention],
      name: data[:name],
      action_id: data[:action_id]
    })
    |> Repo.insert!()
  end

  def update_file_data!(%Files.File{} = old_file_data, new_file_data) do
    old_file_data
    |> Files.File.changeset(new_file_data)
    |> Repo.update!()
  end

  def add_file!(%Plug.Upload{} = upload, action_id) do
    Repo.transaction(fn ->
      file =
        %{
          name: upload.filename |> String.split(".") |> Enum.fetch!(0),
          extention: Path.extname(upload.filename),
          action_id: action_id
        }
        |> add_file_data!()

      file
      |> Files.File.changeset(%{
        check_sum: upload!(upload.path, file_path(file.uuid, file.extention))
      })
      |> Repo.update!()
    end)
  end

  def delete_file!(%{uuid: uuid, extention: ext} = _file) do
    Repo.get_by(Files.File, uuid: uuid)
    |> Repo.delete!()

    if File.exists?(file_path(uuid, ext)) do
      File.rm!(file_path(uuid, ext))
    end
  end

  def delete_files!([]), do: :ok

  def delete_files!([file | files]) do
    delete_file!(file)
    delete_files!(files)
  end

  def file_path(%Files.File{} = file), do: @dist_files <> file.uuid <> file.extention

  def file_path(filename), do: @dist_files <> filename
  def file_path(uuid, ext), do: @dist_files <> uuid <> ext

  defp upload!(src_path, dist_path) do
    case File.cp(src_path, dist_path) do
      :ok ->
        init_hash = :crypto.hash_init(:sha256)

        File.stream!(dist_path, 2024)
        |> Enum.reduce(init_hash, fn chunk, acc ->
          :crypto.hash_update(acc, chunk)
        end)
        |> :crypto.hash_final()
        |> Base.encode16(case: :lower)

      e ->
        raise(InternalServerError, "Не удалось загрузить файл, ошибка: #{inspect(e)}")
    end
  end

  def upload_file(uuid, send_func) do
    file = get_by_uuid(uuid)
    IO.puts("file: #{inspect(file)} uuid #{uuid}")
    path = file_path(file)

    if File.exists?(path) do
      path
      |> File.stream!(@chunk_size)
      |> Enum.reduce(0, fn data, acc ->
        data
        |> Base.encode64()
        |> create_chunk(file, acc)
        |> send_func.()

        acc + 1
      end)
    end
  end

  def load_file(chunk) do
    case chunk do
      %{
        index: index,
        uuid: uuid,
        chunk_data: data,
        extention: ext
      } ->
        if index == 0 && File.exists?(file_path(uuid, ext)) do
          File.rm!(file_path(uuid, ext))
        end

        File.write(file_path(uuid, ext), data |> Base.decode64!(), [:append])

      _ ->
        :error
    end
  end

  defp create_chunk(data, file, index) do
    %{
      index: index,
      uuid: file.uuid,
      extention: file.extention,
      chunk_data: data
    }
  end
end
