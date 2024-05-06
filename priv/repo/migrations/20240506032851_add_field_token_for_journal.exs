defmodule MediaServer.Repo.Migrations.AddFieldTokenForJournal do
  use Ecto.Migration

  def change do
    alter table("journal") do
      add :token, :string
    end
  end
end
