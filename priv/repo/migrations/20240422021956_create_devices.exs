defmodule MediaServer.Repo.Migrations.CreateDevices do
  use Ecto.Migration

  def change do
    create table("devices") do
      add(:description, :string)
      add(:token, :string)
      add(:last_active, :utc_datetime)
    end

    create table("device_tags") do
      add(:device_id, references(:devices, on_delete: :delete_all))
      add(:tag_id, references(:tags))
    end
  end
end
