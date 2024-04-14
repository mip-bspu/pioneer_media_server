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
alias MediaServer.Files
alias MediaServer.Tags
alias MediaServer.Actions
alias MediaServer.Users
alias MediaServer.Util.TimeUtil

tags = Repo.all(Tags.Tag) |> Enum.map(fn tag -> tag.name end)
initial_tags = Application.get_env(:media_server, :initial_tags)

Enum.each(initial_tags -- tags, fn tag ->
  %Tags.Tag{}
  |> Tags.Tag.changeset(%{
    name: tag,
    owner: nil,
    type: "node"
  })
  |> Repo.insert!()
end)

admin =
  %Users.Group{}
  |> Users.Group.changeset(%{
    name: "ADMIN"
  })
  |> Repo.insert!()

user =
  %Users.Group{}
  |> Users.Group.changeset(%{
    name: "USER"
  })
  |> Repo.insert!()

if Mix.env() == :dev do
  %Users.User{}
  |> Users.User.changeset(%{
    login: "admin",
    password: "admin",
    groups: [admin]
  })
  |> Repo.insert!()

  %Users.User{}
  |> Users.User.changeset(%{
    login: "user",
    password: "user",
    groups: [user],
    tags: Repo.all(Tags.Tag)
  })
  |> Repo.insert!()

  if Application.get_env(:media_server, :queue_parent) == nil do
    tag_office =
      %Tags.Tag{}
      |> Tags.Tag.changeset(%{
        name: "office",
        owner: nil,
        type: "device"
      })
      |> Repo.insert!()

    tag_city = Repo.get_by(Tags.Tag, name: "city")
    tag_blg = Repo.get_by(Tags.Tag, name: "blg")

    date = TimeUtil.current_date_time()

    # %Actions.Action{}
    # |> Actions.Action.changeset(%{
    #   name: "action 1",
    #   date_create: date,
    #   from: Timex.shift(date, days: 3),
    #   to: Timex.shift(date, days: 6),
    #   priority: 0,
    #   tags: [tag_blg, tag_city],
    #   files: []
    # })
    # |> IO.inspect()

    # %Content.File{}
    # |> Content.File.changeset(%{
    #   uuid: "abcd",
    #   date_create: date,
    #   extention: ".pdf",
    #   name: "content 1",
    #   check_sum: "aaaa",
    #   tags: [tag_blg, tag_office]
    # })
    # |> Repo.insert!()

    # %Content.File{}
    # |> Content.File.changeset(%{
    #   uuid: "cccc",
    #   date_create: date,
    #   extention: ".pdf",
    #   name: "content 2",
    #   check_sum: "abaa",
    #   tags: [tag_blg, tag_city]
    # })
    # |> Repo.insert!()

    # %Content.File{}
    # |> Content.File.changeset(%{
    #   uuid: Ecto.UUID.generate(),
    #   date_create: date,
    #   extention: ".pdf",
    #   name: "content 3",
    #   check_sum: "aaba",
    #   tags: [tag_city]
    # })
    # |> Repo.insert!()

    # %Content.File{}
    # |> Content.File.changeset(%{
    #   uuid: Ecto.UUID.generate(),
    #   date_create: Timex.shift(date, months: -1),
    #   extention: ".pdf",
    #   name: "content 4",
    #   check_sum: "aaab",
    #   tags: [tag_blg]
    # })
    # |> Repo.insert!()

    # %Content.File{}
    # |> Content.File.changeset(%{
    #   uuid: Ecto.UUID.generate(),
    #   date_create: Timex.shift(date, months: -1, days: 3),
    #   extention: ".pdf",
    #   name: "content 5",
    #   check_sum: "bbaa",
    #   tags: [tag_blg]
    # })
    # |> Repo.insert!()

    # %Content.File{}
    # |> Content.File.changeset(%{
    #   uuid: Ecto.UUID.generate(),
    #   date_create: Timex.shift(date, months: -1, days: 3, minutes: 1),
    #   extention: ".pdf",
    #   name: "content 6",
    #   check_sum: "baba",
    #   tags: [tag_blg]
    # })
    # |> Repo.insert!()

    # %Content.File{}
    # |> Content.File.changeset(%{
    #   uuid: Ecto.UUID.generate(),
    #   date_create: Timex.shift(date, months: -2),
    #   extention: ".pdf",
    #   name: "content 7",
    #   check_sum: "baab",
    #   tags: [tag_blg]
    # })
    # |> Repo.insert!()

    # %Content.File{}
    # |> Content.File.changeset(%{
    #   uuid: Ecto.UUID.generate(),
    #   date_create: Timex.shift(date, months: -2),
    #   extention: ".pdf",
    #   name: "content 12",
    #   check_sum: "baab"
    # })
    # |> Repo.insert!()
  end

  if Application.get_env(:media_server, :queue_parent) != nil do
    %Tags.Tag{}
    |> Tags.Tag.changeset(%{
      name: "office",
      owner: nil,
      type: "device"
    })
    |> Repo.insert!()
  end
end
