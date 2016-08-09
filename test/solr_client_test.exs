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

  test "cast_to_journals" do
    # when response has no docs
    response = Poison.decode! "{\"responseHeader\":{\"status\":0,\"QTime\":7,\"params\":{\"q\":\"issn_ss:05793009\",\"wt\":\"json\",\"fq\":\"format:journal\"}},\"response\":{\"numFound\":0,\"start\":0,\"maxScore\":0.0,\"docs\":[]},\"facet_counts\":{\"facet_queries\":{},\"facet_fields\":{},\"facet_dates\":{},\"facet_ranges\":{},\"facet_intervals\":{}}}\n"
    assert [] == SolrClient.cast_to_journals(response)

    # when there is an error response
    solr_error = %{"error" => %{"code" => 503, "msg" => "no servers hosting shard: "}, "responseHeader" => %{"QTime" => 5, "params" => %{"fq" => "format:journal", "q" => "issn_ss:14697629", "wt" => "json"}, "status" => 503}}
    assert [] == SolrClient.cast_to_journals(solr_error)
  end
end
