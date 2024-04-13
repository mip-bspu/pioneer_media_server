defmodule MediaServer.Users.group do
  use Ecto.Schema

  import Ecto.Changeset

  schema "groups" do
    field(:role, :string)
  end

  def changeset(item, params \\ %{}) do
  end
end
