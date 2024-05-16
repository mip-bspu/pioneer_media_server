defmodule MediaServer.Actions do
  require Logger

  alias MediaServer.Repo
  alias MediaServer.Actions
  alias MediaServer.Tags
  alias MediaServer.Files
  alias MediaServer.Util.TimeUtil
  alias MediaServer.Util.QueryUtil

  import Ecto.Query

  ####################
  # sync actions api #
  ####################

  @filtered_by_tags """
    with action_with_arr_tags as (
      select a.id, a.uuid, a.name, priority, date_create, a.from, a.to, array_agg(t.name) as tags
      from actions a
        left join action_tags ata on a.id = ata.action_id
        left join tags t on t.id = ata.tag_id
      group by a.id, a.uuid, a.name, priority, date_create, a.from, a.to
      order by date_create, a.uuid
    ), data_files as (
      select action_id, string_agg(concat(f.name, check_sum),'.') as data_file
      from (select f.name, check_sum, action_id from files f order by f.name, check_sum) f
      group by action_id
    ), action_with_arr_tags_and_hash_content as (
      select a.id, a.uuid, a.name, priority, date_create, a.from, a.to, tags,
          md5(data_file) as hash_content
      from action_with_arr_tags a
        left join data_files f on f.action_id = a.id
      order by date_create, a.uuid
    ), filtered_by_tags as (
      select * from action_with_arr_tags_and_hash_content where $1 @> tags::text[] or tags::text[] = ARRAY[NULL]
    )
  """

  @query_hash_rows """
    #{@filtered_by_tags}
    select date_create, uuid, md5(concat(
      name, uuid, priority,
      ft.from, ft.to, hash_content,
      to_char(date_create, 'YYYY-MM-DD HH24:MI:SS')
    )) as msum from filtered_by_tags ft
  """

  @query_hash_months """
    with check_sum as (
      #{@query_hash_rows} order by date_create, uuid
    ) select to_char(date_create, 'MM-YYYY') as label, md5(string_agg(msum, '')) from check_sum group by label
  """

  def months_state(tags) do
    QueryUtil.query_select(@query_hash_months, [tags])
  end

  @query_hash_days_of_month """
    with check_sum as (
      #{@query_hash_rows} order by date_create, uuid
    ) select to_char(date_create, 'DD-MM-YYYY') as label, md5(string_agg(msum, '')) from check_sum
    where cast(date_create as date) between $2 and $3 group by label
  """

  def days_of_month_state(tags, date) do
    {begin_month, end_month} = TimeUtil.month_period(TimeUtil.parse_date(date, "{0M}-{YYYY}"))
    QueryUtil.query_select(@query_hash_days_of_month, [tags, begin_month, end_month])
  end

  @query_hash_rows_of_day """
    with check_sum as (
      #{@query_hash_rows} order by date_create, uuid
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

  def get_by_uuid(uuid) do
    Repo.get_by(Actions.Action, uuid: uuid)
    |> Repo.preload(:tags)
    |> Repo.preload(:files)
  end

  def delete_by_uuid!(uuid) do
    action = get_by_uuid(uuid)

    if action do
      Files.delete_files!(action.files)
    end

    action
    |> Repo.delete!()
  end

  def add_action(%{name: name, from: from, to: to} = params) do
    %Actions.Action{}
    |> Actions.Action.changeset(%{
      name: name,
      date_create: params[:date_create] || TimeUtil.current_date_time(),
      uuid: params[:uuid] || Ecto.UUID.generate(),
      from: from,
      to: to,
      priority: params[:priority] || 0,
      tags: params[:tags] && Tags.get_tags(params[:tags])
    })
    |> Repo.insert()
  end

  def update_action(
        %Actions.Action{} = old_action,
        %{
          name: name,
          from: from,
          to: to,
          priority: priority,
          tags: tags
        } = _new_action_data
      ) do
    old_action
    |> Actions.Action.changeset(%{
      name: name || old_action.name,
      from: from || old_action.from,
      to: to || old_action.to,
      priority: priority || old_action.priority,
      tags: (tags && tags |> Tags.get_tags()) || []
    })
    |> Repo.update()
  end

  def action_normalize(action) do
    %{
      name: action.name,
      uuid: action.uuid,
      from: action.from |> TimeUtil.from_iso_to_date!(),
      to: action.to |> TimeUtil.from_iso_to_date!(),
      priority: action.priority,
      date_create: action.date_create |> TimeUtil.from_iso_to_date!(),
      tags:
        action.tags
        |> Enum.map(fn tag ->
          %{
            name: tag.name,
            type: tag.type
          }
        end),
      files: Files.normalize_files(action.files)
    }
  end

  def list_actions(tags, page, page_size) do
    {
      get_total_actions(tags),
      get_page_actions(tags, page, page_size)
      |> Repo.all()
      |> Repo.preload(:tags)
      |> Repo.preload(:files)
    }
  end

  def list_actions_from_period(tags, from, to) do
    query_actions_by_tags(tags)
    |> where([a], (^from <= a.from and a.from <= ^to) or (^from <= a.to and a.to <= ^to))
    |> Repo.all()
    |> Repo.preload(:tags)
    |> Repo.preload(:files)
  end

  def list_actions_before_date(list_tags, date) do
    query_actions_by_tags(list_tags)
    |> where([q], q.to > ^date)
    |> Repo.all()
    |> Repo.preload(:files)
    |> Repo.preload(:tags)
  end

  defp get_total_actions(list_tags) do
    query_actions_by_tags(list_tags)
    |> select([a], [a.uuid, a.id])
    |> Repo.all()
    |> length
  end

  defp get_page_actions(tags, page, page_size) do
    query_actions_by_tags(tags)
    |> limit(^page_size)
    |> offset(^(page * page_size))
  end

  defp query_actions_by_tags(list_tags) do
    from(a in Actions.Action,
      left_join: t in assoc(a, :tags),
      group_by: [a.id],
      having: fragment("? @> array_agg(?) or array_agg(?)::text[] = ARRAY[NULL]", ^[nil | list_tags], t.name, t.name)
    )

    # from(a in Actions.Action,
    #    distinct: true,
    #    left_join: t in assoc(a, :tags),
    #    where: t.name in ^list_tags or is_nil(t.name)
    # )
  end
end
