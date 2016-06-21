defmodule HoldingsMetadata do
  import SweetXml

  def update_needed? do
    online_mod_time > file_mod_time
  end

  def online_mod_time do
    metadata_api.body |> parse_creation_date |> Util.TimeConversion.to_timestamp
  end

  def parse_creation_date(xml) do
    date = xpath(xml, ~x"//creation_date/text()"s)
    year = String.slice(date, 0, 4) |> String.to_integer
    month = String.slice(date, 4, 2) |> String.to_integer
    day = String.slice(date, 6, 2) |> String.to_integer
    {{year, month, day}, {0, 0, 0} }
  end

  def metadata_api do
    {:ok, api} = Application.fetch_env(:enricher, :sfx_metadata_api)
    api
  end

  def file_mod_time do
    Util.TimeConversion.to_timestamp(file_mtime)
  end

  def file_mtime do
    {:ok, file_location} = Application.fetch_env(:enricher, :sfx_file_location)
    case File.lstat(file_location) do
      {:ok, %File.Stat{mtime: mtime}} -> mtime
      {:error, _} -> Util.TimeConversion.unix_epoch
    end
  end
end
