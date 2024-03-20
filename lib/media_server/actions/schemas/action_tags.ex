defmodule MediaServer.Actions.ActionTags do
  use Ecto.Schema

  alias MediaServer.Actions
  alias MediaServer.Tags

  schema "action_tags" do
    belongs_to :action, Actions.Action
    belongs_to :tag, Tags.Tag
  end
end
