defmodule MediaServer.Repo.Migrations.AddFieldsForJournal do
  use Ecto.Migration

  def change do
    alter table("journal") do
      add :filename, :string
      add :ext, :string
    end
  end
end
