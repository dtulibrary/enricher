defmodule SolrClientTest do
  use ExUnit.Case, async: true

  test "query params" do
    assert SolrClient.journal_query_string("issn_ss", "12345678") == "fq=format%3Ajournal&q=issn_ss%3A12345678&wt=json"
  end

  test "mock" do
    # make sure that case thing is working properly
    jqs = SolrClient.journal_query_string("issn_ss", "12345678")
    assert SolrClient.TestFetcher.get(jqs) == SolrClient.TestFetcher.journal_response
  end

  describe "cast_to_journals" do
    test "when response has no docs" do
      response = Poison.decode! "{\"responseHeader\":{\"status\":0,\"QTime\":7,\"params\":{\"q\":\"issn_ss:05793009\",\"wt\":\"json\",\"fq\":\"format:journal\"}},\"response\":{\"numFound\":0,\"start\":0,\"maxScore\":0.0,\"docs\":[]},\"facet_counts\":{\"facet_queries\":{},\"facet_fields\":{},\"facet_dates\":{},\"facet_ranges\":{},\"facet_intervals\":{}}}\n"
      assert [] == SolrClient.cast_to_journals(response)
    end

   test "when there is an error response" do
      solr_error = %{"error" => %{"code" => 503, "msg" => "no servers hosting shard: "}, "responseHeader" => %{"QTime" => 5, "params" => %{"fq" => "format:journal", "q" => "issn_ss:14697629", "wt" => "json"}, "status" => 503}}
      assert [] == SolrClient.cast_to_journals(solr_error)
   end
  end
  describe "cast to docs" do 
    test "when there is an invalid json response" do
      response = "{\"responseHeader\":{\"status\":0,\"QTime\":4,\"params\":{\"sort\":\"id asc\",\"fl\":\"id, cluster_id_ss, issn_ss, eissn_ss, isbn_ss, fulltext_list_ssf, access_ss, format\",\"q\":\"format:article OR format:book\",\"cursorMark\":\"*\",\"wt\":\"json\",\"rows\":\"10\"}},\"response\":{\"numFound\":4200,\"start\":0,\"docs\":[{\"access_ss\":[\"dtupub\",\"dtu\"],\"format\":\"article\",\"cluster_id_ss\":[\"2842957\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"arxiv\\\",\\\"local\\\":false,\\\"type\\\":\\\"other\\\",\\\"url\\\":\\\"http://arxiv.org/abs/0908.3349\\\"}\"],\"id\":\"0\"},{\"access_ss\":[\"dtupub\",\"dtu\"],\"format\":\"article\",\"cluster_id_ss\":[\"3139121\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"arxiv\\\",\\\"local\\\":false,\\\"type\\\":\\\"other\\\",\\\"url\\\":\\\"http://arxiv.org/abs/0801.1253\\\"}\"],\"id\":\"1\"},{\"access_ss\":[\"dtupub\",\"dtu\"],\"format\":\"article\",\"cluster_id_ss\":[\"3444778\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"arxiv\\\",\\\"local\\\":false,\\\"type\\\":\\\"other\\\",\\\"url\\\":\\\"http://arxiv.org/abs/0710.3111\\\"}\"]"
    assert [] == response |> SolrClient.decode |> SolrClient.cast_to_docs
    end
  end

  test "get_docs" do
    response = Poison.decode! "{\"responseHeader\":{\"status\":0,\"QTime\":4,\"params\":{\"sort\":\"id asc\",\"fl\":\"id, cluster_id_ss, issn_ss, eissn_ss, isbn_ss, fulltext_list_ssf, access_ss, format\",\"q\":\"format:article OR format:book\",\"cursorMark\":\"*\",\"wt\":\"json\",\"rows\":\"10\"}},\"response\":{\"numFound\":4200,\"start\":0,\"docs\":[{\"access_ss\":[\"dtupub\",\"dtu\"],\"format\":\"article\",\"cluster_id_ss\":[\"2842957\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"arxiv\\\",\\\"local\\\":false,\\\"type\\\":\\\"other\\\",\\\"url\\\":\\\"http://arxiv.org/abs/0908.3349\\\"}\"],\"id\":\"0\"},{\"access_ss\":[\"dtupub\",\"dtu\"],\"format\":\"article\",\"cluster_id_ss\":[\"3139121\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"arxiv\\\",\\\"local\\\":false,\\\"type\\\":\\\"other\\\",\\\"url\\\":\\\"http://arxiv.org/abs/0801.1253\\\"}\"],\"id\":\"1\"},{\"access_ss\":[\"dtupub\",\"dtu\"],\"format\":\"article\",\"cluster_id_ss\":[\"3444778\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"arxiv\\\",\\\"local\\\":false,\\\"type\\\":\\\"other\\\",\\\"url\\\":\\\"http://arxiv.org/abs/0710.3111\\\"}\"],\"id\":\"10\"},{\"issn_ss\":[\"21511950\",\"21511969\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"scirp\\\",\\\"local\\\":true,\\\"type\\\":\\\"openaccess\\\",\\\"url\\\":\\\"scirp?pi=%2Fjournal%2FPaperDownload.aspx%3FDOI%3D10.4236%2Fjgis.2009.11007&key=193206913\\\"}\"],\"access_ss\":[\"dtupub\",\"dtu\"],\"format\":\"article\",\"cluster_id_ss\":[\"84586616\"],\"id\":\"100\"},{\"access_ss\":[\"dtu\"],\"format\":\"article\",\"cluster_id_ss\":[\"184569811\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"hindawi\\\",\\\"local\\\":false,\\\"type\\\":\\\"publisher\\\",\\\"url\\\":\\\"http://dx.doi.org/10.1100/tsw.2010.219\\\"}\"],\"id\":\"1000\"},{\"access_ss\":[\"dtu\"],\"format\":\"article\",\"cluster_id_ss\":[\"184569812\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"hindawi\\\",\\\"local\\\":false,\\\"type\\\":\\\"publisher\\\",\\\"url\\\":\\\"http://dx.doi.org/10.1100/tsw.2010.207\\\"}\"],\"id\":\"1001\"},{\"access_ss\":[\"dtu\"],\"format\":\"article\",\"cluster_id_ss\":[\"184569813\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"hindawi\\\",\\\"local\\\":false,\\\"type\\\":\\\"publisher\\\",\\\"url\\\":\\\"http://dx.doi.org/10.1100/tsw.2010.226\\\"}\"],\"id\":\"1002\"},{\"access_ss\":[\"dtu\"],\"format\":\"article\",\"cluster_id_ss\":[\"184569814\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"hindawi\\\",\\\"local\\\":false,\\\"type\\\":\\\"publisher\\\",\\\"url\\\":\\\"http://dx.doi.org/10.1100/tsw.2010.213\\\"}\"],\"id\":\"1003\"},{\"access_ss\":[\"dtu\"],\"format\":\"article\",\"cluster_id_ss\":[\"184569815\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"hindawi\\\",\\\"local\\\":false,\\\"type\\\":\\\"publisher\\\",\\\"url\\\":\\\"http://dx.doi.org/10.1100/tsw.2010.201\\\"}\"],\"id\":\"1004\"},{\"access_ss\":[\"dtu\"],\"format\":\"article\",\"cluster_id_ss\":[\"184569816\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"hindawi\\\",\\\"local\\\":false,\\\"type\\\":\\\"publisher\\\",\\\"url\\\":\\\"http://dx.doi.org/10.1100/tsw.2010.203\\\"}\"],\"id\":\"1005\"}]},\"nextCursorMark\":\"AoEkMTAwNQ==\",\"facet_counts\":{\"facet_queries\":{},\"facet_fields\":{},\"facet_dates\":{},\"facet_ranges\":{},\"facet_intervals\":{},\"facet_heatmaps\":{}}}\n"
    assert is_list(SolrClient.get_docs(response))
end
end

