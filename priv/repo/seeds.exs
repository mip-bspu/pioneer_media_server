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

tags = Repo.all(Content.Tag)
initial_tags = Application.get_env(:media_server, :initial_tags)

Enum.each(initial_tags -- tags, fn tag ->
  %Content.Tag{}
  |> Content.Tag.changeset(%{
    name: tag
  })
  |> Repo.insert!()
end)

if Mix.env() == :dev do
  if Application.get_env(:media_server, :queue_parent) == nil && Repo.all(Content.File) == [] do
    tag_city = Repo.get_by(Content.Tag, name: "city")
    tag_blg = Repo.get_by(Content.Tag, name: "blg")

    date = TimeUtil.current_date_time()

    %Content.File{}
    |> Content.File.changeset(%{
      uuid: "abcd",
      date_create: date,
      extention: ".pdf",
      name: "content 1",
      check_sum: "aaaa",
      tags: [tag_blg]
    })
    |> Repo.insert!()

    %Content.File{}
    |> Content.File.changeset(%{
      uuid: "cccc",
      date_create: date,
      extention: ".pdf",
      name: "content 2",
      check_sum: "abaa",
      tags: [tag_blg, tag_city]
    })
    |> Repo.insert!()

    %Content.File{}
    |> Content.File.changeset(%{
      uuid: Ecto.UUID.generate(),
      date_create: date,
      extention: ".pdf",
      name: "content 3",
      check_sum: "aaba",
      tags: [tag_city]
    })
    |> Repo.insert!()

    %Content.File{}
    |> Content.File.changeset(%{
      uuid: Ecto.UUID.generate(),
      date_create: Timex.shift(date, months: -1),
      extention: ".pdf",
      name: "content 4",
      check_sum: "aaab",
      tags: [tag_blg]
    })
    |> Repo.insert!()

    %Content.File{}
    |> Content.File.changeset(%{
      uuid: Ecto.UUID.generate(),
      date_create: Timex.shift(date, months: -1, days: 3),
      extention: ".pdf",
      name: "content 5",
      check_sum: "bbaa",
      tags: [tag_blg]
    })
    |> Repo.insert!()

    %Content.File{}
    |> Content.File.changeset(%{
      uuid: Ecto.UUID.generate(),
      date_create: Timex.shift(date, months: -1, days: 3, minutes: 1),
      extention: ".pdf",
      name: "content 6",
      check_sum: "baba",
      tags: [tag_blg]
    })
    |> Repo.insert!()

    %Content.File{}
    |> Content.File.changeset(%{
      uuid: Ecto.UUID.generate(),
      date_create: Timex.shift(date, months: -2),
      extention: ".pdf",
      name: "content 7",
      check_sum: "baab",
      tags: [tag_blg]
    })
    |> Repo.insert!()

    %Content.File{}
    |> Content.File.changeset(%{
      uuid: Ecto.UUID.generate(),
      date_create: Timex.shift(date, months: -2),
      extention: ".pdf",
      name: "content 12",
      check_sum: "baab"
    })
    |> Repo.insert!()
  end
end
