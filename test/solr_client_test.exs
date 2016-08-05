defmodule SolrClientTest do
  use ExUnit.Case

  test "query params" do
    assert SolrClient.journal_query_string("issn_ss", "12345678") == "fq=format%3Ajournal&q=issn_ss%3A12345678&wt=json"
  end

  test "partial_query" do
    assert SolrClient.partial_query_string == "fl=id%2C+cluster_id_ss%2C+issn_ss%2C+eissn_ss%2C+isbn_ss%2C+fulltext_list_ssf%2C+access_ss%2C+format&fq=format%3Aarticle+OR+format%3Abook&q=fulltext_availability_ss%3AUNDETERMINED+OR+fulltext_info_ss%3Asfx&rows=10000&sort=id+asc&wt=json"
  end

  test "mock" do
    # make sure that case thing is working properly
    jqs = SolrClient.journal_query_string("issn_ss", "12345678")
    assert SolrClient.TestFetcher.get(jqs) == SolrClient.TestFetcher.journal_response

    aqs = SolrClient.article_query_string
    assert SolrClient.TestFetcher.get(aqs) == SolrClient.TestFetcher.all_articles_response
  end

  test "get_coverage" do
    details = [from: {"1947", "42", ""}, to: {"1967", "62", ""}, embargo: 0]
    assert SolrClient.get_coverage("issn", "03702634") == details
  end
end
