defmodule MediaServer.Tags do
  require Logger

  alias MediaServer.Repo
  alias MediaServer.Tags
  alias MediaServer.Users

  import Ecto.Query

  def get_tag_by_name(name), do: Repo.get_by(Tags.Tag, name: name)

  def get_tag_by_id(id), do: Repo.get_by(Tags.Tag, id: id)

  def get_all_tags(), do: from(t in Tags.Tag) |> Repo.all()

  def get_all_my_tags() do
    from(t in Tags.Tag, where: is_nil(t.owner))
    |> Repo.all()
  end

  def get_tags_by_owner(owner) do
    from(t in Tags.Tag, where: t.owner == ^owner)
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
      |> where([t], not (t.type == "node" and is_nil(t.owner)) )

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

  def delete_tag!(%Tags.Tag{} = tag),
    do: tag |> Repo.delete!()

  def add_tags!(child, tags) do
    old_tags = get_tags_by_owner(child) |> normalize_tags()

    remove_tags = old_tags -- tags
    add_tags = tags -- old_tags

    Enum.each(remove_tags, fn tag ->
      get_tag_by_name(tag.name)
      |> Repo.delete!()
    end)

    Enum.each(add_tags, fn tag ->
      %Tags.Tag{}
      |> Tags.Tag.changeset(tag)
      |> Repo.insert!()
    end)
  end

  def check_correct_tags(%Users.User{} = user, tags) do
    if is_list(tags) do
      incorrect_tags =
        if(Users.is_admin(user),
          do: tags -- ( get_filtered_tags() |> Enum.map(&(&1.name)) ),
          else: tags -- Enum.map(user.tags, &(&1.name))
        )

      if length(incorrect_tags) > 0 do
        raise( BadRequestError, "Назначены недопустимые тэги: #{Enum.join(incorrect_tags, ", ")}" )
      end

      tags
    else
      []
    end
  end

  def normalize_tags(tags, owner \\ nil) do
    tags |> Enum.map(fn t -> %{
      name: t.name,
      owner: owner || t.owner,
      type: t.type
    } end)
  end
end
