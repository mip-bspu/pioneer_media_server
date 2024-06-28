defmodule MediaServer.Files do
  require Logger

  alias MediaServer.Repo
  alias MediaServer.Files
  alias MediaServer.Actions
  alias MediaServer.Util.FormatUtil

  import Ecto.Query

  @dist_files Application.compile_env(:media_server, :dist_content, "./files/")
  @chunk_size Application.compile_env(:media_server, :chunk_size, 2000)

  @image_formats Application.compile_env(:media_server, :image_formats)
  @video_formats Application.compile_env(:media_server, :video_formats)

  def get_files_by_action_uuid(uuid) do
    from(
      a in Actions.Action,
      join: f in Files.File,
      on: a.id == f.action_id,
      where: a.uuid == ^uuid,
      select: f
    )
    |> Repo.all()
  end

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
      action_id: data[:action_id],
      timelive_image: data[:time] || nil
    })
    |> Repo.insert!()
  end

  def update_file_data!(%Files.File{} = old, new) do
    old
    |> Files.File.changeset(new)
    |> Repo.update!()
  end

  def update_files!(action, %{ times: times }) do
    action.files
    |> Enum.each(fn file ->
      time = Map.get(Enum.find(times, &(&1.uuid == file.uuid)), :time, nil)

      if not is_nil(time) do
        update_file_data!(file, %{
          timelive_image:  time |> FormatUtil.to_integer()
        })
      end
    end)
  end

  def add_file!(%Plug.Upload{} = upload, action_id, time \\ 10) do
    Repo.transaction(fn ->
      file =
        %{
          name: upload.filename |> String.split(".") |> Enum.fetch!(0),
          extention: Path.extname(upload.filename),
          action_id: action_id,
          time: if(upload.content_type |> String.contains?("image"), do: time, else: nil)
        }
        |> add_file_data!()

      file
      |> Files.File.changeset(%{
        check_sum: upload!(upload.path, file_path(file.uuid, file.extention))
      })
      |> Repo.update!()
    end)
  end

  def add_files!(action, files, times \\ nil) do
    Enum.each(files || [], fn file ->
      ext = Path.extname(file.filename)

      if ext in @image_formats || ext in @video_formats do

        if is_list(times) do
          time = times
            |> Enum.find(fn(t)->file.filename == hd t end)
            |> case do
              nil -> nil
              time -> time |> Enum.at(1) |> FormatUtil.to_integer()
            end

          Files.add_file!(file, action.id, time)
        else
          Files.add_file!(file, action.id)
        end
      end
    end)
  end

  def delete_file!(%{uuid: uuid, extention: ext} = _file) do
    Repo.get_by(Files.File, uuid: uuid)
    |> Repo.delete!()

    if File.exists?(file_path(uuid, ext)) do
      File.rm!(file_path(uuid, ext))
    end
  end

  def delete_files!(action, uuids) do
    action = action |> Repo.preload(:files)

    uuids |> Enum.each(fn uuid ->
      action_file = Enum.find( action.files, &(&1.uuid == uuid) )

      if not is_nil(action_file) do
        delete_file!(action_file)
      end
    end)
  end

  def delete_files!([]), do: :ok

  def delete_files!([file | files]) do
    delete_file!(file)
    delete_files!(files)
  end

  def file_path(file), do: @dist_files <> file.uuid <> file.extention
  def file_path(uuid, ext), do: @dist_files <> uuid <> ext

  defp upload!(src_path, dist_path) do
    case File.cp(src_path, dist_path) do
      :ok ->
        create_hash_sum(dist_path)

      e ->
        raise(InternalServerError, "Не удалось загрузить файл, ошибка: #{inspect(e)}")
    end
  end

  def create_hash_sum(path_dist_file) do
    init_hash = :crypto.hash_init(:sha256)

    File.stream!(path_dist_file, 2024)
    |> Enum.reduce(init_hash, fn chunk, acc ->
      :crypto.hash_update(acc, chunk)
    end)
    |> :crypto.hash_final()
    |> Base.encode16(case: :lower)
  end

  def upload_file(uuid, send_func) do
    file = get_by_uuid(uuid)
    path = file_path(file)

    try do
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

        %{
          state: :last,
          uuid: file.uuid,
          extention: file.extention
        }
        |> send_func.()
      end
    rescue
      e ->
        Logger.error("cancel download file #{file.name}: #{inspect(e)}")

        %{
          state: :cancel,
          uuid: file.uuid,
          extention: file.extention
        }
        |> send_func.()
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
        file_path = file_path(uuid, ext)

        if index == 0 && File.exists?(file_path) do
          File.rm!(file_path)
        end

        File.write(file_path, data |> Base.decode64!(), [:append])

      _ ->
        :error
    end
  end

  defp create_chunk(data, file, index) do
    %{
      state: :load,
      index: index,
      uuid: file.uuid,
      extention: file.extention,
      chunk_data: data
    }
  end

  def normalize_files(files), do: normalize_files(files, [])
  defp normalize_files([], list), do: list

  defp normalize_files([file | files], list_norm_files) do
    normalize_files(files, [
      %{
        uuid: file.uuid,
        extention: file.extention,
        check_sum: file.check_sum,
        name: file.name
      }
      | list_norm_files
    ])
  end
end
