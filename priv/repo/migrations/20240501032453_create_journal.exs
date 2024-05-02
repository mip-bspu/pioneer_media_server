defmodule MediaServer.Repo.Migrations.CreateJournal do
  use Ecto.Migration

  def change do
    create table("journal") do
      add(:action, :string)
      add(:content_uuid, :string)
      add(:priority, :integer)

      timestamps()
    end
  end
end
