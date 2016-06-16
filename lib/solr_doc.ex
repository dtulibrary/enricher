defmodule SolrDoc do

  defstruct [
    :author_ts, :title_ts, :journal_title_ts,  :issn_ss,
    :pub_date_tis, :journal_vol_ssf, :journal_page_ssf,
    :doi_ss, :publisher_ts, :publication_place_ts,
    :cluster_id_ss, :format
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

  def data(sd) do
    # take first vals from multivalued fields 
    transform = fn
      {x, [top | tail]} -> {x, top}
      {x, y} -> {x, y}
    end
    Map.from_struct(sd)
    |> Enum.reject(fn {x, y} -> is_nil(y) end)
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
end
