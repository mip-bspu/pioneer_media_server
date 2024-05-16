defmodule MediaServer.Repo.Migrations.AddFieldTimeliveImageForFiles do
  use Ecto.Migration

  def change do
    alter table("files") do
      add :timelive_image, :integer
    end
  end
end
