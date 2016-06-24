defmodule HoldingsApi do
  import SweetXml

  @fetcher Application.get_env(:enricher, :holdings_fetcher, HoldingsApi.Fetcher)
  @file_url Application.get_env(:enricher, :institutional_holdings_url)

  def fetch do
    download |> unzip
  end

  def download do
    @fetcher.get(@file_url)
  end

  def unzip(zipped_body) do
    # make sure the file doesn't exist
    path = "tmp/output.xml"
    File.rm(path)
    z = :zlib.open
    :zlib.inflateInit(z, 31)
    handler = &File.write(path, &1, [:append])
    unzip_loop(z, handler, :zlib.inflateChunk(z, zipped_body))
    :zlib.inflateEnd(z)
    :zlib.close(z)
    path
  end

  # unzip in chunks until there are no more left
  defp unzip_loop(z, handler, {:more, decompressed}) do
    handler.(decompressed)
    unzip_loop(z, handler, :zlib.inflateChunk(z))
  end

  # the final unzip method, called when there are no more chunks remaining
  defp unzip_loop(_, handler, decompressed) do
    handler.(decompressed)
  end

  def parse(fp) do
    stream = File.stream! fp
    map = %{}
    SweetXml.stream_tags(stream, [:item])
    |> Stream.map(fn {_, doc} -> parse_func(doc) end)
    |> Enum.reduce(map, fn(x, acc) -> Map.merge(acc, x) end)
  end

  defp parse_func(doc) do
    identifier = get_best_identifier(doc)
    from_year = xpath(doc, ~x"//coverage/from/year/text()"s)
    from_vol = xpath(doc, ~x"//coverage/from/volume/text()"s)
    from_issue = xpath(doc, ~x"//coverage/from/issue/text()"s)
    to_year =  xpath(doc, ~x"//coverage/to/year/text()"s)
    to_vol = xpath(doc, ~x"//coverage/to/volume/text()"s)
    to_issue = xpath(doc, ~x"//coverage/to/issue/text()"s)
    from = {from_year, from_vol, from_issue}
    to = {to_year, to_vol, to_issue}
    %{identifier => [from: from, to: to]}
  end

  # Take identifier in preferential order (recursive)
  def get_best_identifier(doc) do
    get_best_identifier(doc, ["issn", "eissn", "isbn"])
  end

  defp get_best_identifier(doc, [type|others]) do
    case xpath(doc, ~x"//#{type}/text()"o) do # o flag means return nil if empty
      nil -> get_best_identifier(doc, others)
      x -> List.to_string(x)
    end
  end

  defmodule Fetcher do
    def get(url) do
      %HTTPoison.Response{body: body} = HTTPoison.get! url
      body
    end
  end

  defmodule TestFetcher do
    def get(_) do
      {:ok, body} = File.read("test/fixtures/institutional_holding.gzip")
      body
    end
  end
end
