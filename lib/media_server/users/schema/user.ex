defmodule MediaServer.Users.User do
  use Ecto.Schema

  import Ecto.Changeset

  alias MediaServer.Users
  alias MediaServer.Tags

  schema "users" do
    many_to_many :groups, Tags.Tag,
      join_through: Users.UserTags,
      on_replace: :delete,
      on_delete: :delete_all

    many_to_many :groups, Users.Group,
      join_through: Users.UserGroups,
      on_replace: :delete,
      on_delete: :delete_all
  end

  def changeset(item, params \\ %{}) do
    item
    |> cast(params, [:tags, :groups])
    |> validate_required([:groups])
    |> put_assoc_if_exist(params[:tags], :tags)
    |> put_assoc_if_exist(params[:groups], :groups)
  end

  def put_assoc_if_exist(item, nil, _key), do: item
  def put_assoc_if_exist(item, list, key), do:
    item |> put_assoc(key, list)
end
