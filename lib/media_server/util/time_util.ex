defmodule MediaServer.Util.TimeUtil do
  import Timex

  @local_zone "Asia/Yakutsk"

  def current_date_time() do
    now() |> to_datetime(@local_zone)
  end

  def to_utc(date) do
    date |> from_iso_to_date!() |> to_datetime(@local_zone)
  end

  def from_iso_to_date!(str) when is_bitstring(str) do
    Timex.parse!(str, "{ISO:Extended}")
  end

  def from_iso_to_date!(str), do: str

  def month_period(date) do
    {date |> Timex.beginning_of_month(), date |> Timex.end_of_month()}
  end

  def parse_date(date), do: parse_date(date, "{YYYY}-{0M}-{0D}")

  def parse_date(date, format) do
    Timex.parse!(date, format)
    |> Timex.to_date()
  end

  def get_date_shift_days(days) do
    Timex.now() |> Timex.to_date() |> Date.add(days)
  end
end
