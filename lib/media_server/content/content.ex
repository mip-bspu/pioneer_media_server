defmodule MediaServer.Content do
  require Logger

  alias MediaServer.Repo
  alias MediaServer.Content
  alias MediaServer.Util.TimeUtil
  alias MediaServer.Util.QueryUtil

  import Ecto.Query

  @dist_files Application.compile_env(:media_server, :dist_content, "./files/")
  @chunk_size 2000

  ####################
  # content sync api #
  ####################

  @filtered_tags """
    with details_file_tags as (
      select uuid, date_create, check_sum, extention, f.name, t.name as tag from files f
        left join file_tags ft on f.id = ft.file_id
        left join tags t on t.id = ft.tag_id
      order by t.name, date_create
    ), array_tags as (
      select uuid, date_create, check_sum, extention, name, array_agg(tag) as tags from details_file_tags ft
      group by uuid, date_create, check_sum, extention, name
    ), filtered_tags as (
      select * from array_tags where $1 @> tags::text[] or tags::text[] = ARRAY[NULL]
    )
  """

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
    QueryUtil.query_select(@query_hash_rows_of_day, [
      tags,
      TimeUtil.parse_date(date, "{0D}-{0M}-{YYYY}")
    ])
  end

  ##################
  # repository api #
  ##################

  def get_by_uuid!(uuid) do
    Repo.get_by!(Content.File, uuid: uuid)
    |> Repo.preload(:tags)
  end

  def get_by_uuid(uuid) do
    Repo.get_by(Content.File, uuid: uuid)
    |> Repo.preload(:tags)
  end

  def get_by_id(id) do
    Repo.get_by(Content.File, id: id)
    |> Repo.preload(:tags)
  end

  defp query_files_assoc_tags_by_tags(tags) do
    from(
      f in Content.File,
      left_join: t in assoc(f, :tags),
      where: t.name in ^tags or is_nil(t.name)
    )
  end

  defp query_paginate(query, page, page_size) do
    from(
      query,
      limit: ^page_size,
      offset: ^(page * page_size)
    )
  end

  def get_page_content(tags, page, page_size) do
    tags
    |> query_files_assoc_tags_by_tags()
    |> query_paginate(page, page_size)
    |> Repo.all()
    |> Repo.preload(:tags)
  end

  def get_by_tags(tags) do
    tags
    |> query_files_assoc_tags_by_tags()
    |> Repo.all()
    |> Repo.preload(:tags)
  end

  def get_all_my_tags() do
    from(t in Content.Tag, where: is_nil(t.owner))
    |> Repo.all()
  end

  def get_by_tags_count(tags) do
    query = query_files_assoc_tags_by_tags(tags)

    from(q in query, select: count(q.uuid))
    |> Repo.one()
  end

  def get_tags(list_tags) do
    from(t in Content.Tag, where: t.name in ^list_tags and is_nil(t.owner))
    |> Repo.all()
  end

  def get_tags(list_tags, owner) do
    from(t in Content.Tag, where: t.name in ^list_tags and t.owner == ^owner)
    |> Repo.all()
  end

  def add_tags(owner, tags) do
    Enum.each(tags, fn tag ->
      %Content.Tag{}
      |> Content.Tag.changeset(%{
        name: tag[:name],
        owner: owner,
        type: tag[:type] || "node"
      })
      |> Repo.insert()
    end)
  end

  def add_file_data!(data) do
    %Content.File{}
    |> Content.File.changeset(%{
      uuid: data[:uuid] || Ecto.UUID.generate(),
      date_create: data[:date_create] || TimeUtil.current_date_time(),
      check_sum: data[:check_sum] || nil,
      extention: data[:extention],
      name: data[:name],
      tags: data[:tags] || []
    })
    |> Repo.insert!()
  end

  def update_file_data!(%Content.File{} = old_file_data, new_file_data) do
    old_file_data
    |> Content.File.changeset(new_file_data)
    |> Repo.update!()
  end

  #########
  # utils #
  #########

  def upload_file(uuid, send_func) do
    content = Content.get_by_uuid!(uuid)
    path = Content.file_path(content)

    if File.exists?(path) do
      path
      |> File.stream!(@chunk_size)
      |> Enum.reduce(0, fn data, acc ->
        data
        |> Base.encode64()
        |> create_chunk(content, acc)
        |> send_func.()

        acc + 1
      end)
    end
  end

  # TODO: exception
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

  def parse_content(file) do
    %{
      file
      | check_sum: file.check_sum || nil,
        # warning: ["a", "b"] = ["b", "a"] // false
        tags:
          Enum.map(file.tags, fn tag -> %{name: tag.name, owner: tag.owner, type: tag.type} end)
    }
  end

  defp create_chunk(data, content, index) do
    %{
      index: index,
      uuid: content.uuid,
      extention: content.extention,
      chunk_data: data
    }
  end

  def file_path(%Content.File{} = file), do: @dist_files <> file.uuid <> file.extention

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

  ####################
  # controller's api #
  ####################
  def add_file!(
        %{name: _name, from: _from, to: _to, tags: tags} = data,
        %Plug.Upload{} = upload
      ) do
    Repo.transaction(fn ->
      file =
        %{data | tags: get_tags(tags)}
        |> Map.put(:extention, Path.extname(upload.filename))
        |> add_file_data!()

      file
      |> Content.File.changeset(%{
        check_sum: upload!(upload.path, file_path(file.uuid, file.extention))
      })
      |> Repo.update!()
    end)
  end

  def update_file!(%{name: name, tags: tags, from: from, to: to, id: id} = _params, upload) do
    Repo.transaction(fn ->
      case get_by_id(id) do
        nil ->
          raise(NotFound, "Такой контент не существует")

        old_content ->
          new_content =
            update_file_data!(old_content, %{
              name: name,
              from: from,
              to: to,
              tags:
                tags
                |> get_tags()
            })

          if upload != nil do
            %{uuid: uuid, extention: ext} = old_content

            if File.exists?(file_path(uuid, ext)) do
              File.rm!(file_path(uuid, ext))
            end

            new_content
            |> Content.File.changeset(%{
              check_sum: upload!(upload.path, file_path(uuid, ext))
            })
            |> Repo.update!()
          end
      end
    end)
  end

  def delete_content!(id) do
    case Content.get_by_id(id) do
      nil ->
        raise(NotFound, "Такой контент не существует")

      %{uuid: uuid, extention: ext} = content ->
        if File.exists?(file_path(uuid, ext)) do
          File.rm!(file_path(uuid, ext))
        end

        content
        |> Repo.delete!()
    end
  end

  def list_content(page, page_size, tags) do
    count = get_by_tags_count(tags)
    list = get_page_content(tags, page, page_size)

    {count, list}
  end
end
