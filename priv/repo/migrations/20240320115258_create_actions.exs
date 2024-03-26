defmodule MediaServer.Repo.Migrations.CreateActions do
  use Ecto.Migration

  def change do
    create table("actions") do
      add(:name, :string)
      add(:uuid, :string)
      add(:priority, :integer)
      add(:date_create, :utc_datetime)
      add(:from, :utc_datetime)
      add(:to, :utc_datetime)
    end

    create table("tags") do
      add(:name, :string)
      add(:owner, :string)
      add(:type, :string)
    end

    create unique_index(:tags, [:name])
    create unique_index(:actions, [:uuid])

    create table("action_tags") do
      add(:action_id, references(:actions, on_delete: :delete_all))
      add(:tag_id, references(:tags))
    end
  end
end
