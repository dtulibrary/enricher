defmodule SolrJournal do
  defstruct [ :holdings_ssf, :title_ts, :embargo_ssf, issn_ss: [], eissn_ss: []]
  use ExConstructor

  def holdings(%SolrJournal{holdings_ssf: nil}), do: "NONE"

  def holdings(%SolrJournal{holdings_ssf: holdings_json}) do
    holdings = SolrJournal.Holdings.from_json(holdings_json)
    [
      from: SolrJournal.Holdings.from(holdings),
      to: SolrJournal.Holdings.to(holdings),
      embargo: SolrJournal.Holdings.embargo(holdings)
    ]
  end

  def embargo(%SolrJournal{embargo_ssf: nil}), do: 0
  def embargo(%SolrJournal{embargo_ssf: []}), do: 0
  def embargo(%SolrJournal{embargo_ssf: terms}) do
    terms |> Enum.map(&String.to_integer/1) |> Enum.sort |> Kernel.hd
  end

  @doc """
  Given a journal with an embargo represented as days
  Convert this to years, rounding up.

  ## Examples
  
      iex> SolrJournal.embargo_years(%SolrJournal{embargo_ssf: ["256"]})
      1
      iex> SolrJournal.embargo_years(%SolrJournal{embargo_ssf: ["110"]})
      1
      iex> SolrJournal.embargo_years(%SolrJournal{})
      0

  """
  def embargo_years(solr_journal) do
    solr_journal
    |> embargo
    |> to_nearest_year
  end

  def to_nearest_year(days) do
    days
    |> Kernel./(365)
    |> Float.ceil
    |> Kernel.trunc
  end
  def valid?(%SolrJournal{holdings_ssf: nil}), do: false

  def valid?(%SolrJournal{holdings_ssf: holdings}) do 
    Enum.all?(holdings, fn(h) ->
      SolrJournal.Holdings.from_json(h) |> Map.get(:fromyear) |> Kernel.is_binary
    end)
  end

  def invalid_message(journal) do
    unless valid?(journal) do
      message = "INVALID: #{title(journal)} - #{issn(journal)} - "
      case journal.holdings_ssf do
        nil -> message <> "No holdings data"
        _ -> message <> "No from year"
      end  
    end  
  end

  @doc """
  Determine whether a given article is within a journal's embargo period.  
  """
  def under_embargo?(journal: journal, article: article) do
    under_embargo?(journal: journal, article: article, current_year: DateTime.utc_now.year)
  end

  @doc """
  Determine whether a given article is within a journal's embargo period. This interface is more testable as it is not dependent on the current year.

  ## Examples

      iex>SolrJournal.under_embargo?(journal: %SolrJournal{}, article: %SolrDoc{pub_date_tis: [2016]}, current_year: 2016)
      false

      iex>SolrJournal.under_embargo?(journal: %SolrJournal{embargo_ssf: ["256"]}, article: %SolrDoc{pub_date_tis: [2016]}, current_year: 2016)
      true

   """
  def under_embargo?(journal: journal, article: article, current_year: current_year) do
    case SolrJournal.embargo_years(journal) do
      0 -> false
      embargo_years -> 
        SolrDoc.year(article) > (current_year - embargo_years)
    end
  end

  def holdings_ranges(%SolrJournal{holdings_ssf: holdings}) do
     Enum.map(holdings, fn(h) ->
       SolrJournal.Holdings.from_json(h) |> SolrJournal.Holdings.year_range
     end)
  end

  @doc "Open access journals contain the string 'open access' in their titles"
  def open_access?(%SolrJournal{title_ts: titles}) do
    Enum.any?(titles, fn(x) ->
      String.downcase(x) |> String.contains?("open access")
    end)
  end

  def within_holdings?(journal: journal, article: article) do
    cond do
      holdings(journal) == "NONE" -> false
      Enum.any?(holdings_ranges(journal), &Enum.member?(&1, SolrDoc.year(article))) ->
        true
      :else -> false
    end
  end


  @identifiers [:issn_ss, :eissn_ss]

  @doc """
  Given a journal, return a list of all its
  identifiers in the form ["identifier:value"]
  
  ## Examples

      iex> SolrJournal.identifiers(%SolrJournal{issn_ss: ["12345678", "98765432"]})
      ["issn_ss:12345678", "issn_ss:98765432"]
      iex> SolrJournal.identifiers(%SolrJournal{issn_ss: ["12345678"], eissn_ss: ["98765432"]})
      ["eissn_ss:98765432", "issn_ss:12345678"]
      iex> SolrJournal.identifiers(%SolrJournal{})
      []
  """
  def identifiers(journal) do
    Enum.reduce(@identifiers, [], fn(id, acc) ->
      Map.get(journal, id)
      |> Enum.map(fn(val) -> "#{id}:#{val}" end)
      |> Enum.concat(acc)
    end)
  end

  def title(%SolrJournal{title_ts: nil}), do: ""
  def title(%SolrJournal{title_ts: []}), do: ""
  def title(%SolrJournal{title_ts: [t|_]}), do: t

  def issn(%SolrJournal{issn_ss: nil}), do: ""
  def issn(%SolrJournal{issn_ss: []}), do: ""
  def issn(%SolrJournal{issn_ss: [t|_]}), do: t

  defmodule Holdings do
    defstruct [:fromyear, :fromvolume, :fromissue, :tovolume, :toissue, :embargo, toyear: "#{DateTime.utc_now.year}"]
    use ExConstructor

    def from_json([head|_]) do
      from_json(head)
    end

    def from_json(json_blob) do
      case Poison.decode(json_blob) do
        {:ok, hld} -> Holdings.new(hld)
        {:error, _} -> IO.inspect json_blob
      end
    end

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

    def year_range(hld) do
      # Correct for possible errors in from years
      fromyear = case hld.fromyear do
        nil -> hld.toyear
        number -> number
      end
      String.to_integer(fromyear)..String.to_integer(hld.toyear)
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
