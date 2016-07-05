defmodule SolrDoc do

  defstruct [
    :author_ts, :title_ts, :journal_title_ts,  :issn_ss,
    :pub_date_tis, :journal_vol_ssf, :journal_page_ssf,
    :doi_ss, :publisher_ts, :publication_place_ts,
    :cluster_id_ss, :format, :holdings_ssf, :isbn_ss,
    :journal_issue_ssf, :fulltext_list_ssf, :id
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

  @identifiers [:issn_ss, :eissn_ss, :isbn_ss]

  @doc """
  Get the first identifier present in the document
  and return a tuple with the identifier and the value

  ## Example

  SolrDoc.identifier(%SolrDoc{issn_ss: ["1234-5678"]})

  => {"issn_ss", "1234-5678"}
  """
  def identifier(solr_doc) do
     identifier = data(solr_doc) |> first_identifier
     value = data(solr_doc) |> Map.get(identifier)
     {"#{identifier}", value}
  end

  defp first_identifier(data) do
    Map.keys(data)
    |> Enum.find(&(Enum.member?(@identifiers, &1)))
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

  @doc "Convert keys to keys for OpenUrl module"
  def open_url_map(sd) do
    Map.new(data(sd), fn {x,y} -> { Map.get(field_map(sd), x), y } end)
  end

  def to_open_url_query(sd) do
    open_url_map(sd) |> OpenUrl.new |> OpenUrl.to_uri
  end

  @doc "Returns the correct field mapping for the given document's format"
  def field_map(sd) do
    Map.get(@field_mappings, sd.format)
  end

  def year(doc) do
     doc.pub_date_tis |> hd
  end

  def fulltext_types(%SolrDoc{fulltext_list_ssf: nil}), do: nil
  def fulltext_types(%SolrDoc{fulltext_list_ssf: fulltext}) do
    fulltext |> Enum.map(fn x ->
      Poison.decode!(x) |> Map.get("type")
    end)
  end

end
