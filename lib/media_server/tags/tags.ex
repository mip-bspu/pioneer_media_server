defmodule MediaServer.Tags do
  require Logger

  alias MediaServer.Repo
  alias MediaServer.Tags

  import Ecto.Query

  def get_tag_by_name(name), do: Repo.get_by(Tags.Tag, name: name)

  def get_all_tags(), do: get_filtered_tags()
  def get_all_my_tags() do
    from(t in Tags.Tag, where: is_nil(t.owner))
    |> Repo.all()
  end

  def get_tags(list_tags) do
    from(t in Tags.Tag, where: t.name in ^list_tags)
    |> Repo.all()
  end

  def get_filtered_tags(filter \\ %{list_tags: :none, list_types: :none}) do
    list_tags = Access.get(filter, :list_tags, :none)
    list_types = Access.get(filter, :list_types, :none)

    query = from(t in Tags.Tag)

    query =
      if list_tags != :none,
        do: query |> where([t], t.name in ^list_tags),
        else: query

    query =
      if list_types != :none,
        do: query |> where([t], t.type in ^list_types),
        else: query

    query
    |> Repo.all()
  end

  def create_tag(tag, owner\\nil) do
    %Tags.Tag{}
    |> Tags.Tag.changeset(%{
      name: tag[:name],
      owner: owner,
      type: tag[:type] || "node"
    })
    |> Repo.insert()
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
