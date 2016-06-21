defmodule Util do
  defmodule TimeConversion do
    # See http://michal.muskala.eu/2015/07/30/unix-timestamps-in-elixir.html
    @unix_epoch {{1970, 1, 1}, {0, 0, 0}}
    @epoch :calendar.datetime_to_gregorian_seconds(@unix_epoch)

    def to_timestamp(dt) do
      dt
      |> :calendar.datetime_to_gregorian_seconds
      |> -(@epoch)
    end

    def unix_epoch, do: @unix_epoch
  end
end
