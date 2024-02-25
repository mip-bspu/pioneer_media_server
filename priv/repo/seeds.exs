# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     MediaServer.Repo.insert!(%MediaServer.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias MediaServer.Repo
alias MediaServer.Content
alias MediaServer.Util.TimeUtil

if Mix.env() == :dev do

  if Application.get_env(:media_server, :parent) == [] && Repo.all(Content.File) == [] do
    date = TimeUtil.current_date_time()

    %Content.File{}
    |> Content.File.changeset(%{
      uuid: Ecto.UUID.generate(),
      date_create: date,
      extention: ".pdf",
      name: "content 1",
      tags: %{
        0 => %{name: "city"}
      }
    })
    |> Repo.insert!()

    %Content.File{}
    |> Content.File.changeset(%{
      uuid: Ecto.UUID.generate(),
      date_create: date,
      extention: ".pdf",
      name: "content 2",
      tags: %{
        0 => %{name: "school"},
        1 => %{name: "city"}
      }
    })
    |> Repo.insert!()

    %Content.File{}
    |> Content.File.changeset(%{
      uuid: Ecto.UUID.generate(),
      date_create: date,
      extention: ".pdf",
      name: "content 3",
      tags: %{
        0 => %{name: "school"},
      }
    })
    |> Repo.insert!()

    %Content.File{}
    |> Content.File.changeset(%{
      uuid: Ecto.UUID.generate(),
      date_create: Timex.shift(date, months: -1),
      extention: ".pdf",
      name: "content 4",
      tags: %{
        0 => %{name: "school"},
      }
    })
    |> Repo.insert!()

    %Content.File{}
    |> Content.File.changeset(%{
      uuid: Ecto.UUID.generate(),
      date_create: Timex.shift(date, months: -2),
      extention: ".pdf",
      name: "content 5",
      tags: %{
        0 => %{name: "school"},
      }
    })
    |> Repo.insert!()
  end
end
