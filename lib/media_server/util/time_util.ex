defmodule MediaServer.Util.TimeUtil do
  import Timex

  @local_zone "Asia/Yakutsk"

  def current_date_time() do
    now() |> to_datetime(@local_zone)
  end
end
