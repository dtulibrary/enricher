defmodule SolrDoc do

  defstruct [
    :author_ts, :title_ts, :journal_title_ts,  :issn_ss,
    :pub_date_tis, :journal_vol_ssf, :journal_page_ssf,
    :doi_ss, :publisher_ts, :publication_place_ts,
    :cluster_id_ss, :format, :holdings_ssf
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

  def journal_holdings(solr_doc) do
    {:ok, hld} = Poison.decode(solr_doc.holdings_ssf)
    holdings = SolrDoc.Holdings.new(hld)
    [
      from: SolrDoc.Holdings.from(holdings),
      to: SolrDoc.Holdings.to(holdings),
      embargo: SolrDoc.Holdings.embargo(holdings)
    ]
  end

  defmodule Holdings do
    defstruct [:fromyear, :fromvolume, :fromissue, :toyear, :tovolume, :toissue, :embargo]
    use ExConstructor

    def from(holdings) do
      [holdings.fromyear, holdings.fromvolume, holdings.fromissue]
      |> holdings_tuple
    end

    def to(holdings) do
      [holdings.toyear, holdings.tovolume, holdings.toissue]
      |> holdings_tuple
    end

    def embargo(holdings) do
      case holdings.embargo do
        nil -> 0
        x -> x
      end
    end

    defp holdings_tuple(data_enum) do
      nils_to_strings = fn
        nil ->  ""
        x -> x
      end
      data_enum
      |> Enum.map(&nils_to_strings.(&1))
      |> Enum.reduce({}, fn(x, acc) -> Tuple.append(acc, x) end)
    end
  end
end
