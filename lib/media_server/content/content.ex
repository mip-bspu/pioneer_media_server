defmodule MediaServer.Content do
  require Logger

  alias MediaServer.Repo
  alias MediaServer.Content
  alias MediaServer.Util.TimeUtil
  alias MediaServer.Util.QueryUtil

  @dist_files Application.compile_env(:media_server, :dist_content, "./files/")

  @filtered_tags """
    with details_file_tags as (
      select uuid, date_create, check_sum, extention, f.name, t.name as tag from files f
        join file_tags ft on f.id = ft.file_id
        join tags t on t.id = ft.tag_id
      order by t.name, date_create
    ), array_tags as (
      select uuid, date_create, check_sum, extention, name, array_agg(tag) as tags from details_file_tags ft
      group by uuid, date_create, check_sum, extention, name
    ), filtered_tags as (
      select * from array_tags where ARRAY[$1] && tags::text[]
    )
  """

  @query_get_by_tags """
    #{@filtered_tags}
    select * from filtered_tags
  """

  def get_by_tags(tags) do
    QueryUtil.query_select(@query_get_by_tags, [Enum.join(tags, ", ")])
  end

  @query_hash_rows """
    #{@filtered_tags}
    select date_create, uuid, md5(concat(
      name, tags,
      uuid, extention, check_sum,
      to_char(date_create, 'YYYY-MM-DD HH24:MI:SS')
    )) as msum from filtered_tags
  """

  @query_hash_months """
    with check_sum as (
      #{@query_hash_rows} order by date_create
    ) select to_char(date_create, 'YYYY-MM') as label, md5(string_agg(msum, '')) from check_sum group by label;
  """

  def months_state(tags) do
    IO.inspect(tags)
    QueryUtil.query_select(@query_hash_months, [Enum.join(tags, ", ")])
  end

  @hash_days_of_month_query """

  """

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
