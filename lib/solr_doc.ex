defmodule SolrDoc do

  defstruct [
    :author_ts, :title_ts, :journal_title_ts,  :issn_ss,
    :eissn_ss, :pub_date_tis, :journal_vol_ssf, :journal_page_ssf,
    :doi_ss, :publisher_ts, :publication_place_ts,
    :cluster_id_ss, :format, :holdings_ssf, :isbn_ss,
    :journal_issue_ssf, :fulltext_list_ssf, :id, :source_ss
  ]
  use ExConstructor

  @field_mappings %{
    "book" => %{
      author_ts: :au,
      title_ts: :btitle,
      pub_date_tis: :year,
      pub_date_tis: :date,
      doi_ss: :doi,
      publisher_ts: :pub,
      publication_place_ts: :place,
      format: :genre,
      isbn_ss: :isbn
    },
    "article" => %{
      author_ts: :au,
      title_ts: :atitle,
      journal_title_ts: :jtitle,
      issn_ss: :issn,
      pub_date_tis: :year,
      pub_date_tis: :date,
      journal_vol_ssf: :volume,
      journal_issue_ssf: :issue,
      journal_page_ssf: :pages,
      journal_page_ssf: :spage,
      journal_page_ssf: :epage,
      doi_ss: :doi,
      publisher_ts: :pub,
      publication_place_ts: :place,
      format: :genre
    }
  }

  @identifiers [:issn_ss, :eissn_ss]

  @doc """
  Get the first identifier present in the document
  and return a tuple with the identifier and the value

  ## Example

  SolrDoc.identifier(%SolrDoc{issn_ss: ["1234-5678"]})

  => {"issn_ss", "1234-5678"}
  """
  def identifier(solr_doc) do
     identifier = solr_doc |> data |> first_identifier
     value =  solr_doc |> data |> Map.get(identifier)
     {"#{identifier}", value}
  end

  defp first_identifier(data) do
    Map.keys(data)
    |> Enum.find(&(Enum.member?(@identifiers, &1)))
  end

  @doc """
  Returns all identifiers from a document

  ## Examples

      iex> SolrDoc.all_identifiers(%SolrDoc{issn_ss: [12345678, 87654321]})
      [{"issn_ss", "12345678"}, {"issn_ss", "87654321"}]

  """
  def all_identifiers(solr_doc) do
    get_tup = fn(ident, map) ->
      case Map.fetch(map, ident) do
        {:ok, values} when is_list(values) -> 
          Enum.map(values, &{"#{ident}", &1})
        {:ok, nil} -> [nil]
        {:ok, value} -> [{"#{ident}", value}]
        :error -> [nil]
      end
    end
    @identifiers |> Enum.flat_map(&get_tup.(&1, solr_doc)) |> Enum.reject(&is_nil/1)
  end

  def data(sd) do
    # take first vals from multivalued fields
    transform = fn
      {x, [top | _]} -> {x, top}
      {x, y} -> {x, y}
    end
    Map.from_struct(sd)
    |> Enum.reject(fn {_, y} -> is_nil(y) end)
    |> Enum.into(Map.new, &transform.(&1))
  end

  @doc "Returns the correct field mapping for the given document's format"
  def field_map(sd) do
    Map.get(@field_mappings, sd.format)
  end

  def year(%SolrDoc{pub_date_tis: [pub_date|_]}), do: pub_date
  def year(%SolrDoc{pub_date_tis: nil}), do: nil

  def fulltext_types(%SolrDoc{fulltext_list_ssf: nil}), do: nil
  def fulltext_types(%SolrDoc{fulltext_list_ssf: fulltext}) do
    fulltext |> Enum.map(fn x ->
      Poison.decode!(x) |> Map.get("type")
    end)
  end

  def pure_source?(%SolrDoc{source_ss: nil}), do: false
  def pure_source?(%SolrDoc{source_ss: sources}) do
    Enum.any?(sources, fn(s) -> Regex.match?(~r/orbit|rdb_/,s) end)
  end

  def fulltext_url?(%SolrDoc{fulltext_list_ssf: nil}), do: false
  def fulltext_url?(%SolrDoc{fulltext_list_ssf: fulltext}) do
    case Poison.decode(fulltext) do
      {:ok, body} -> Map.has_key?(body, "url")
      _ -> false
    end
  end
end
