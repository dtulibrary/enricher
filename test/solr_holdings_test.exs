defmodule SolrHoldingsTest do
  use ExUnit.Case

  test "get_coverage" do
    details = [from: {"1947", "42", ""}, to: {"1967", "62", ""}, embargo: 0]
    assert SolrHoldings.get_coverage("issn", "03702634") == details
  end

end
