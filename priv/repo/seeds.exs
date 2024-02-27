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
alias MediaServer.NodeServer
alias MediaServer.Util.TimeUtil

if Mix.env() == :dev do
  if Application.get_env(:media_server, :parents) == [] && Repo.all(Content.File) == [] do
    date = TimeUtil.current_date_time()

    %Content.File{}
    |> Content.File.changeset(%{
      uuid: "abcd",
      date_create: date,
      extention: ".pdf",
      name: "content 1",
      check_sum: "aaaa",
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
      check_sum: "abaa",
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
      check_sum: "aaba",
      tags: %{
        0 => %{name: "school"}
      }
    })
    |> Repo.insert!()

    %Content.File{}
    |> Content.File.changeset(%{
      uuid: Ecto.UUID.generate(),
      date_create: Timex.shift(date, months: -1),
      extention: ".pdf",
      name: "content 4",
      check_sum: "aaab",
      tags: %{
        0 => %{name: "school"}
      }
    })
    |> Repo.insert!()

    %Content.File{}
    |> Content.File.changeset(%{
      uuid: Ecto.UUID.generate(),
      date_create: Timex.shift(date, months: -1, days: 3),
      extention: ".pdf",
      name: "content 5",
      check_sum: "bbaa",
      tags: %{
        0 => %{name: "school"}
      }
    })
    |> Repo.insert!()

    %Content.File{}
    |> Content.File.changeset(%{
      uuid: Ecto.UUID.generate(),
      date_create: Timex.shift(date, months: -1, days: 3, minutes: 1),
      extention: ".pdf",
      name: "content 6",
      check_sum: "baba",
      tags: %{
        0 => %{name: "school"}
      }
    })
    |> Repo.insert!()

    %Content.File{}
    |> Content.File.changeset(%{
      uuid: Ecto.UUID.generate(),
      date_create: Timex.shift(date, months: -2),
      extention: ".pdf",
      name: "content 7",
      check_sum: "baab",
      tags: %{
        0 => %{name: "school"}
      }
    })
    |> Repo.insert!()
  end

  if Application.get_env(:media_server, :parents) != [] do
    %NodeServer.Node{}
    |> NodeServer.Node.changeset(%{name: "section1"})
    |> Repo.insert!()

    %NodeServer.Node{}
    |> NodeServer.Node.changeset(%{name: "section2"})
    |> Repo.insert!()
  end
end
