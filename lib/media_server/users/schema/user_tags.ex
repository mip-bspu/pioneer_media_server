defmodule MediaServer.Users.UserTags do
  use Ecto.Schema

  alias MediaServer.Users
  alias MediaServer.Tags

  schema "user_groups" do
    belongs_to :user, Users.User
    belongs_to :tag, Tags.Tag
  end
end
