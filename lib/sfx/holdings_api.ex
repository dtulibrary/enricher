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
    SweetXml.stream_tags(stream, [:item])
    |> Stream.map(fn {_, doc} -> parse_func(doc) end)
    |> Enum.reduce(%{}, fn(x, acc) -> Map.merge(acc, x) end)
  end

  defp parse_func(doc) do
    identifier = get_best_identifier(doc)
    from = parse_section(doc, "from")
    to = parse_section(doc, "to")
    %{identifier => [from: from, to: to]}
  end

  # take year, volume and issue from section and return a tuple of strings
  # e.g. {"1966", "14", "1"}
  def parse_section(doc, section) do
    Enum.map(["year", "volume", "issue"], fn(x) -> parse_text(doc, section, x) end)
    |> Enum.reduce({}, fn(x, acc) -> Tuple.append(acc, x) end)
  end

  defp parse_text(doc, section, unit) do
    case xpath(doc, ~x"//coverage/#{section}/#{unit}/text()") do
      nil -> ""
      x -> List.to_string(x)
    end
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

  # if no identifiers present in doc
  defp get_best_identifier(_, []), do: "UNDEFINED"

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
