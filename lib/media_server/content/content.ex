defmodule MediaServer.Content do
  require Logger

  alias MediaServer.Repo
  alias MediaServer.Content
  alias MediaServer.Util.TimeUtil
  alias MediaServer.Util.QueryUtil

  @dist_files Application.compile_env(:media_server, :dist_content, "./files/")
  @chunk_size 2000

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
      select * from array_tags where $1 && tags::text[]
    )
  """

  @query_get_by_tags """
    #{@filtered_tags}
    select * from filtered_tags
  """

  def get_by_tags(tags) do # check: sql injection
    QueryUtil.query_select(@query_get_by_tags, [tags])
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
    ) select to_char(date_create, 'MM-YYYY') as label, md5(string_agg(msum, '')) from check_sum group by label
  """

  def months_state(tags) do
    QueryUtil.query_select(@query_hash_months, [tags])
  end

  @query_hash_days_of_month """
    with check_sum as (
      #{@query_hash_rows} order by date_create
    ) select to_char(date_create, 'DD-MM-YYYY') as label, md5(string_agg(msum, '')) from check_sum
    where cast(date_create as date) between $2 and $3 group by label
  """

  def days_of_month_state(tags, date) do
    {begin_month, end_month} = TimeUtil.month_period(TimeUtil.parse_date(date, "{0M}-{YYYY}"))
    QueryUtil.query_select(@query_hash_days_of_month, [tags, begin_month, end_month])
  end

  @query_hash_rows_of_day """
    with check_sum as (
      #{@query_hash_rows} order by date_create
    ) select uuid as label, msum from check_sum
    where cast(date_create as date) = $2
  """

  def rows_of_day_state(tags, date) do
    QueryUtil.query_select(@query_hash_rows_of_day, [tags, TimeUtil.parse_date(date, "{0D}-{0M}-{YYYY}")])
  end

  def get_by_uuid!(uuid) do
    Repo.get_by!(Content.File, uuid: uuid)
    |> Repo.preload(:tags)
  end

  def get_by_uuid(uuid) do
    Repo.get_by(Content.File, uuid: uuid)
    |> Repo.preload(:tags)
  end

  def parse_content(%Content.File{} = file) do
    %{
      name: file.name,
      check_sum: file.check_sum || "",
      uuid: file.uuid,
      date_create: file.date_create,
      tags: Enum.map(file.tags, fn(tag)->tag.name end)
    }
  end

  def file_path(%Content.File{} = file), do: @dist_files <> file.uuid <> file.extention

  def file_path(filename), do: @dist_files <> filename
  def file_path(uuid, ext), do: @dist_files <> uuid <> ext



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

  def load_file(uuid, send_func) do
    content = Content.get_by_uuid!(uuid)

    content
    |> Content.file_path()
    |> File.stream!(@chunk_size)
    |> get_chunk(content)
    |> send_func.()
  end

  def get_chunk(data, content) do
    %{
      uuid: content.uuid,
      ext: content.extention,
      chunk_data: data
    }
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
