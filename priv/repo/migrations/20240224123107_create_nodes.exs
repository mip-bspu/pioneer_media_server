defmodule MediaServer.Repo.Migrations.CreateNodes do
  use Ecto.Migration

  def change do
    create table("nodes") do
      add :name, :string
      add :ping, :integer
    end

    create unique_index(:nodes, [:name])
  end
end
