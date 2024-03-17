defmodule MediaServer.Tags do
  require Logger

  alias MediaServer.Repo
  alias MediaServer.Tags

  import Ecto.Query

  def get_all_my_tags() do
    from(t in Tags.Tag, where: is_nil(t.owner))
    |> Repo.all()
  end

  def get_tags(list_tags) do
    from(t in Tags.Tag, where: t.name in ^list_tags)
    |> Repo.all()
  end

  def get_filtered_tags(%{list_tags: list_tags, owner: owner, type: type}) do
  end

  def add_tags(owner, tags) do
    Enum.each(tags, fn tag ->
      %Tags.Tag{}
      |> Tags.Tag.changeset(%{
        name: tag[:name],
        owner: owner,
        type: tag[:type] || "node"
      })
      |> Repo.insert()
    end)
  end
end
