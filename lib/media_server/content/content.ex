defmodule MediaServer.Content do
  alias MediaServer.Repo
  alias MediaServer.Content
  alias MediaServer.Util.TimeUtil
  alias MediaServer.Util.QueryUtil

  @dist_files Application.compile_env(:media_server, :dist_content, "./files/")

  @hash_rows_query """
    select date_create, uuid, md5(concat(
      name,
      uuid, extention, check_sum,
      to_char(date_create, 'YYYY-MM-DD HH24:MI:SS')
    )) as msum from files
  """

  @hash_months_query """
    with check_sum as (
      #{@hash_rows_query} order by date_create
    ) select to_char(date_create, 'YYYY-MM') as label, md5(string_agg(msum, '')) from check_sum group by label;
  """

  @hash_days_of_month_query """

  """

  def months_state(tags) do
    QueryUtil.query_select(@hash_months_query, [])
  end

  def file_path(filename), do: @dist_files <> filename
  def file_path(name, ext), do: @dist_files <> name <> ext

  def add_file!(name, %Plug.Upload{} = upload, tags) do
    Repo.transaction(fn ->
      extention = Path.extname(upload.filename)

      {_, map_tags} = Enum.reduce(tags, {0, %{}}, fn(tag, {index, map})->
        {
          index + 1,
          Map.put(map, index, %{name: tag})
        }
      end)


      file =
        %Content.File{}
        |> Content.File.changeset(%{
          uuid: Ecto.UUID.generate(),
          date_create: TimeUtil.current_date_time(),
          extention: extention,
          name: name,
          tags: map_tags
        })
        |> Repo.insert!()

      file
      |> Content.File.changeset(%{
        check_sum: upload!(upload.path, file_path(file.uuid, file.extention))
      })
      |> Repo.update!()
    end)
  end

  def upload!(src_path, dist_path) do
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
end
