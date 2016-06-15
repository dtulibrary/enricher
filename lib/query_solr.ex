defmodule QuerySolr do
  def get_ids do
     fetch
     |> handle_response
     |> decode
     |> parse_ids
  end

  def get_docs do
    fetch
    |> handle_response
    |> decode
  end

  def fetch do
    HTTPoison.get("http://localhost:8983/solr/metastore/select?q=*%3A*&wt=json&indent=true")
  end

  def handle_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    { :ok, body }
  end

  @doc """
  This method signature is incorrect
  """
  def handle_response(%{status_code: _, body: body}), do: { :error, body }

  def decode({:ok, body}) do
    Poison.decode(body)
  end

  def parse_ids({:ok, solr_response}) do
    docs = solr_response["response"]["docs"]
    Enum.flat_map(docs, fn(doc) -> doc["cluster_id_ss"] end)
  end

  def cast_to_docs({:ok, solr_response}) do
     docs = solr_response["response"]["docs"]
     Enum.flat_map(docs, fn(doc) -> doc end)
  end
end
