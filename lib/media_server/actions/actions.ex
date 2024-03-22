defmodule MediaServer.Actions do
  require Logger

  alias MediaServer.Actions
  alias MediaServer.Tags
  alias MediaServer.Repo
  alias MediaServer.Util.TimeUtil
  alias MediaServer.Files

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
