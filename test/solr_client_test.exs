defmodule SolrClientTest do
  use ExUnit.Case

  test "query params" do
    assert SolrClient.journal_query_string("issn_ss", "12345678") == "fq=format%3Ajournal&q=issn_ss%3A12345678&wt=json"
  end
end
