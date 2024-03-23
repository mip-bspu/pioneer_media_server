defmodule MediaServer.Actions do
  require Logger

  alias MediaServer.Actions
  alias MediaServer.Tags
  alias MediaServer.Repo
  alias MediaServer.Util.TimeUtil
  alias MediaServer.Util.QueryUtil
  alias MediaServer.Files

  ####################
  # sync actions api #
  ####################

  @filtered_by_tags """
    with action_with_arr_tags as (
      select a.id, a.name, priority, date_create, a.from, a.to, array_agg(t.name) as tags from actions a
        left join action_tags ata on a.id = ata.action_id
        left join tags t on t.id = ata.tag_id
      group by a.id, a.name, priority, date_create, a.from, a.to order by date_create
    ), action_with_arr_tags_and_hash_content as (
      select a.id, a.name, priority, date_create, a.from, a.to, tags,
          md5(concat(string_agg(f.name,'.'), string_agg(f.check_sum, '.'))) as hash_content
        from action_with_arr_tags a
        left join files f on f.action_id = a.id
      group by a.id, a.name, priority, date_create, a.from, a.to, tags order by date_create
    ), filtered_by_tags as (
      select * from action_with_arr_tags_and_hash_content where $1 @> tags::text[] or tags::text[] = ARRAY[NULL]
    )
  """

  @query_hash_rows """
    #{@filtered_by_tags}
    select date_create, name, md5(concat(
      name, tags, priority,
      ft.from, ft.to, hash_content,
      to_char(date_create, 'YYYY-MM-DD HH24:MI:SS')
    )) as msum from filtered_by_tags ft
  """

  @query_hash_months """
    with check_sum as (
      #{@query_hash_rows} order by date_create
    ) select to_char(date_create, 'MM-YYYY') as label, md5(string_agg(msum, '')) from check_sum group by label
  """

  def months_state(tags) do
    QueryUtil.query_select(@query_hash_months, [tags])
  end

  ##################
  # repository api #
  ##################

  def add_action!(%{name: name, from: from, to: to} = params) do
    Repo.transaction(fn ->
      %Actions.Action{}
      |> Actions.Action.changeset(%{
        name: name,
        date_create: TimeUtil.current_date_time(),
        from: from,
        to: to,
        priority: params[:priority] || 0,
        tags: params[:tags] || []
      })
      |> Repo.insert!()
    end)
  end
end
