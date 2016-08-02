defmodule AccessDeciderTest do
  use ExUnit.Case

  setup do
    oa_doc = SolrDoc.new(%{
      "source_type_ss" => ["openaccess"],
      "fulltext_list_ssf" =>
      ["{\"source\":\"doaj\",\"local\":false,\"type\":\"openaccess\",\"url\":\"http://arbor.revistas.csic.es/index.php/arbor/article/view/964/971\"}"]
      })
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
      book_doc = SolrDoc.new(solr_book)
    {:ok, open_access: oa_doc, book: book_doc}
  end

  test "create_updater - open access article", %{open_access: oa_doc} do
    decision = AccessDecider.create_update(oa_doc)
    assert ["dtupub", "dtu"] == decision.fulltext_access
    assert "metastore" == decision.fulltext_info
  end

  test "create_updater - book", %{book: book} do
    decision = AccessDecider.create_update(book)
    assert ["dtu"] == decision.fulltext_access
    assert "sfx" == decision.fulltext_info
  end

  test "pure fulltext" do
    pure_doc_with_fulltext = SolrDoc.new(%{
      "source_type_ss" => ["research"],
      "fulltext_list_ssf" => [
        "{\"source\":\"rdb_vbn\",\"local\":false,\"type\":\"research\",\"url\":\"http://vbn.aau.dk/ws/files/228080680/PnP_iMG_DC_TCST_final.pdf\"}"
      ]
      })
    decision = AccessDecider.create_update(pure_doc_with_fulltext)
    assert ["dtupub", "dtu"] == decision.fulltext_access
    assert "metastore" == decision.fulltext_info

    pure_doc_no_fulltext = SolrDoc.new(%{"source_type_ss" => ["research"]})
    decision = AccessDecider.create_update(pure_doc_no_fulltext)
    assert [] == decision.fulltext_access
    assert "none" == decision.fulltext_info
  end
end
