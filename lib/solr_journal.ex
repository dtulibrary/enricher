defmodule SolrJournal do
  defstruct [:issn_ss, :holdings_ssf, :title_ts]
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
      String.to_integer(hld.fromyear)..String.to_integer(hld.toyear)
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
