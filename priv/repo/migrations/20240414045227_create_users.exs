defmodule MediaServer.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table("groups") do
      add(:name, :string)
    end

    create table("users") do
      add(:login, :string)
      add(:password, :string)
      add(:active, :boolean)
    end

    create unique_index(:users, [:login])

    create table("user_tags") do
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:tag_id, references(:tags))
    end

    create table("user_groups") do
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:group_id, references(:groups))
    end
  end
end
