defmodule MediaServer.Repo.Migrations.CreateFiles do
  use Ecto.Migration

  def change do
    create table("files") do
      add(:uuid, :string)
      add(:date_create, :utc_datetime)
      add(:check_sum, :string)
      add(:extention, :string)
      add(:name, :string)
    end
  end
end
