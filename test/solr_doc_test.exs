defmodule SolrDocTest do
  use ExUnit.Case, async: true
  doctest SolrJournal
  setup do
    solr_article = %{
      "_version_" => 1535294313411379200,
      "abstract_ts" => ["In this paper we present an alternative viewpoint on recent studies of regularity of solutions to the Navier-Stokes equations in critical spaces. In particular, we prove that mild solutions which remain bounded in the space $\\dot H^{1/2}$ do not become singular in finite time, a result which was proved in a more general setting by L. Escauriaza, G. Seregin and V. Sverak using a different approach. We use the method of \"concentration-compactness\" + \"rigidity theorem\" which was recently developed by C. Kenig and F. Merle to treat critical dispersive equations. To the authors' knowledge, this is the first instance in which this method has been applied to a parabolic equation. We remark that we have restricted our attention to a special case due only to a technical restriction, and plan to return to the general case (the $L^3$ setting) in a future publication.", "Comment: 41 pages"],
      "access_ss" => ["dtupub", "dtu"],
      "alert_timestamp_dt" => "2015-10-22T12:11:45.753Z",
      "author_facet" => ["Kenig, Carlos E.", "Koch, Gabriel S."],
      "author_ts" => ["Kenig, Carlos E.", "Koch, Gabriel S."],
      "cluster_id_ss" => ["2842957"],
      "format" => "article",
      "fulltext_availability_ss" => ["UNDETERMINED"],
      "fulltext_list_ssf" => ["{\"source\":\"arxiv\",\"local\":false,\"type\":\"other\",\"url\":\"http://arxiv.org/abs/0908.3349\"}"],
      "id" => "0",
      "keywords_facet" => ["Mathematics - Analysis of PDEs"],
      "keywords_ts" => ["Mathematics - Analysis of PDEs"],
      "member_id_ss" => ["146834317"],
      "pub_date_tis" => [2009],
      "source_ext_ss" => ["ds1:arxiv"],
      "source_id_ss" => ["arxiv:oai:arXiv.org:0908.3349"],
      "source_ss" => ["arxiv"],
      "source_type_ss" => ["other"],
      "issn_ss" =>["16123174"],
      "title_ts" => ["An alternative approach to regularity for the Navier-Stokes equations in critical spaces"],
      "update_timestamp_dt" => "2015-10-22T12:11:51.904Z",
      "~merge_info_sf" => "{\"abstract_ts\":[\"(arxiv,*) / 146834317\"],\"author_sort\":[\"(arxiv,*) / 146834317\"],\"author_ts\":[\"(arxiv,*) / 146834317\"],\"cluster_id_ss\":[\"(arxiv,*) / 146834317\"],\"format\":[\"(arxiv,*) / 146834317\"],\"fulltext_list_ssf\":[\"(arxiv,*) / 146834317\"],\"keywords_ts\":[\"(arxiv,*) / 146834317\"],\"member_id_ss\":[\"(arxiv,*) / 146834317\"],\"pub_date_tis\":[\"(arxiv,*) / 146834317\"],\"pub_date_tsort\":[\"(arxiv,*) / 146834317\"],\"source_ext_ss\":[\"(arxiv,*) / 146834317\"],\"source_id_ss\":[\"(arxiv,*) / 146834317\"],\"source_ss\":[\"(arxiv,*) / 146834317\"],\"source_type_ss\":[\"(arxiv,*) / 146834317\"],\"title_sort\":[\"(arxiv,*) / 146834317\"],\"title_ts\":[\"(arxiv,*) / 146834317\"]}"}
    solr_book = %{
      "access_ss"=>["dtu"],
      "alert_timestamp_dt"=>"2016-01-08T22:26:32.862Z",
      "isolanguage_ss"=>["eng"],
      "isolanguage_facet"=>["eng"],
      "publisher_ts"=>["Springer"],
      "member_id_ss"=>["469007235"],
      "title_ts"=>["Integrative human biochemistry"],
      "source_ss"=>["dtu_sfx"],
      "language_ss"=>["English"],
      "format"=>"book",
      "update_timestamp_dt"=>"2016-01-09T01:11:13.533Z",
      "pub_date_tis"=>[2018],
      "journal_page_ssf"=>["1 online resource"],
      "isbn_ss"=>["1493930583", "1493930575", "9781493930586", "9781493930579"],
      "fulltext_availability_ss"=>["UNDETERMINED"],
      "cluster_id_ss"=>["277030343"],
      "source_id_ss"=>["dtu_sfx:ocn932002484"],
      "author_ts"=>["Castanho, Miguel A. R. B."],
      "author_facet"=>["Castanho, Miguel A. R. B."],
      "source_ext_ss"=>["ds1:dtu_sfx"],
      "source_type_ss"=>["other"],
      "affiliation_associations_json"=>"{\"editor\":[],\"supervisor\":[],\"author\":[null]}",
      "id"=>"1463226154",
      "_version_"=>1529502562036744193,
      "timestamp"=>"2016-03-22T11:48:30.289Z",
      "score"=>17.687468
    }
    article = SolrDoc.new(solr_article)
    book = SolrDoc.new(solr_book)

    {:ok, article: article, book: book}
  end

  test "constructor", %{article: sd} do
    assert sd.author_ts == ["Kenig, Carlos E.", "Koch, Gabriel S."]
    assert sd.format == "article"
    assert sd.title_ts == ["An alternative approach to regularity for the Navier-Stokes equations in critical spaces"]
  end

  test "data", %{article: sd} do
    data = SolrDoc.data(sd)
    assert data.title_ts == "An alternative approach to regularity for the Navier-Stokes equations in critical spaces"
    assert data.author_ts == "Kenig, Carlos E."
  end

  test "field_map" do
    article = SolrDoc.new(%{"format" => "article"})
    assert Map.get(SolrDoc.field_map(article), :title_ts) == :atitle

    book = SolrDoc.new(%{"format" => "book"})
    assert Map.get(SolrDoc.field_map(book), :title_ts) == :btitle
  end

  test "identifier", %{article: article} do
    assert SolrDoc.identifier(article) == {"issn_ss", "16123174"}
  end

  describe "identifiers" do
    test "multiple issns" do
      assert SolrDoc.all_identifiers(%SolrDoc{issn_ss: ["12345678", "87654321"]}) == [{"issn_ss", "12345678"}, {"issn_ss", "87654321"}]
    end
    test "issns and eissn" do
      assert SolrDoc.all_identifiers(%SolrDoc{issn_ss: ["12345678", "87654321"], eissn_ss: ["12344321"]}) == [{"issn_ss", "12345678"}, {"issn_ss", "87654321"}, {"eissn_ss", "12344321"}]
    end
  end

  test "year" do
    with_year = %SolrDoc{author_ts: nil, cluster_id_ss: ["2"], doi_ss: nil, format: "article", fulltext_list_ssf: ["{\"source\":\"cell\",\"local\":true,\"type\":\"publisher\",\"url\":\"http://production.datastore.cvt.dk/filestore?oid=56d7441cddbb323376032b30&targetid=56d7441cddbb323376032b32\"}"], holdings_ssf: nil, id: "1", isbn_ss: nil, issn_ss: ["10974172", "00928674"], journal_issue_ssf: nil, journal_page_ssf: nil, journal_title_ts: nil, journal_vol_ssf: nil, pub_date_tis: [2018], publication_place_ts: nil, publisher_ts: nil, title_ts: nil}
    no_year = %SolrDoc{author_ts: nil, cluster_id_ss: ["2"], doi_ss: nil, format: "article", fulltext_list_ssf: ["{\"source\":\"cell\",\"local\":true,\"type\":\"publisher\",\"url\":\"http://production.datastore.cvt.dk/filestore?oid=56d7441cddbb323376032b30&targetid=56d7441cddbb323376032b32\"}"], holdings_ssf: nil, id: "1", isbn_ss: nil, issn_ss: ["10974172", "00928674"], journal_issue_ssf: nil, journal_page_ssf: nil, journal_title_ts: nil, journal_vol_ssf: nil, pub_date_tis: nil, publication_place_ts: nil, publisher_ts: nil, title_ts: nil}
   assert 2018 == SolrDoc.year(with_year)
   assert nil == SolrDoc.year(no_year)
  end
  describe "pure_source?" do
    test "should be true for all pure sources" do
      assert SolrDoc.pure_source?(%SolrDoc{source_ss: ["orbit"]}) 
      assert SolrDoc.pure_source?(%SolrDoc{source_ss: ["sorbit"]})
      assert SolrDoc.pure_source?(%SolrDoc{source_ss: ["rdb_ku"]}) 
      assert SolrDoc.pure_source?(%SolrDoc{source_ss: ["rdb_au"]}) 
      refute SolrDoc.pure_source?(%SolrDoc{source_ss: ["wiley"]}) 
      refute SolrDoc.pure_source?(%SolrDoc{source_ss: ["elsevier"]}) 
      refute SolrDoc.pure_source?(%SolrDoc{source_ss: ["scopus"]}) 
    end
    test "bad values" do
      refute SolrDoc.pure_source?(%SolrDoc{source_ss: []}) 
      refute SolrDoc.pure_source?(%SolrDoc{}) 
    end
  end
  describe "fulltext_url?" do
    test "should be false when there is no fulltext or there is invalid json" do
      refute SolrDoc.fulltext_url?(%SolrDoc{}) 
      refute SolrDoc.fulltext_url?(%SolrDoc{fulltext_list_ssf: []}) 
      refute SolrDoc.fulltext_url?(%SolrDoc{fulltext_list_ssf: ["dkdkdk"]}) 
    end
    test "should be true when there is fulltext" do
      assert SolrDoc.fulltext_url?(%SolrDoc{fulltext_list_ssf: [ "{\"source\":\"sorbit\",\"local\":true,\"type\":\"other\",\"url\":\"http://production.datastore.cvt.dk/filestore?oid=579743b06bbf232e70000f48&targetid=579743b06bbf232e70000f4f\"}"]})
    end
  end
end
