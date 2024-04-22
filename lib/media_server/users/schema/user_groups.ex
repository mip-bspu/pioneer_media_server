defmodule MediaServer.Users.UserGroups do
  use Ecto.Schema

  alias MediaServer.Users

  schema "user_groups" do
    belongs_to :user, Users.User
    belongs_to :group, Users.Group
  end
end
