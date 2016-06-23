defmodule HoldingsApi do

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
  def unzip_loop(z, handler, {:more, decompressed}) do
    handler.(decompressed)
    unzip_loop(z, handler, :zlib.inflateChunk(z))
  end

  # the final unzip method, called when there are no more chunks remaining
  def unzip_loop(z, handler, decompressed) do
    handler.(decompressed)
  end

  # def handler(output) do
  #   IO.puts output
  # end

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
