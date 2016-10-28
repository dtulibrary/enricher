defmodule AccessDeciderTest do
  use ExUnit.Case, async: true

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
    {:ok, cache} = GenServer.start_link(JournalCache, [])
    {:ok, open_access: oa_doc, book: book_doc, fetcher: cache}
  end

  describe "create_update" do 
    test "journals from SFX should be dtu access", %{fetcher: fetcher} do
      decision = AccessDecider.create_update(%SolrDoc{format: "journal", id: "167176061", issn_ss: ["20075626"], journal_title_ts: ["Medicina Hospitalaria"], source_ss: ["jnl_sfx"]}, fetcher)
      assert decision.fulltext_access == ["dtu"]
      assert decision.fulltext_info == "sfx"
    end
    test "journals with open access in the title field should be open access", %{fetcher: fetcher} do
      oa_journal = %SolrDoc{format: "journal", id: "167138337", issn_ss: ["21647860", "21647844"], journal_title_ts: ["Bioresearch Open Access"], source_ss: ["jnl_sfx"], title_ts: nil}
      decision = AccessDecider.create_update(oa_journal, fetcher)
      assert decision.fulltext_access == ["dtupub", "dtu"]
      assert decision.fulltext_info == "metastore"
    end
    test "open access article should be publically accessible", %{open_access: oa_doc, fetcher: fetcher} do
      decision = AccessDecider.create_update(oa_doc, fetcher)
      assert ["dtupub", "dtu"] == decision.fulltext_access
      assert "metastore" == decision.fulltext_info
    end

    test "sfx book should have access dtu", %{book: book, fetcher: fetcher} do
      decision = AccessDecider.create_update(book, fetcher)
      assert ["dtu"] == decision.fulltext_access
      assert "sfx" == decision.fulltext_info
    end

    test "non-sfx book should not have online access", %{fetcher: fetcher} do
      book = %SolrDoc{format: "book", source_ss: ["alis"]}
      decision = AccessDecider.create_update(book, fetcher)
      assert [] == decision.fulltext_access
      assert "none" == decision.fulltext_info  
    end
    test "pure fulltext", %{fetcher: fetcher}  do
      pure_doc_with_fulltext = SolrDoc.new(%{
        "source_type_ss" => ["research"],
        "fulltext_list_ssf" => [
          "{\"source\":\"rdb_vbn\",\"local\":false,\"type\":\"research\",\"url\":\"http://vbn.aau.dk/ws/files/228080680/PnP_iMG_DC_TCST_final.pdf\"}"
        ]
        })
      decision = AccessDecider.create_update(pure_doc_with_fulltext, fetcher)
      assert ["dtupub", "dtu"] == decision.fulltext_access
      assert "metastore" == decision.fulltext_info
    end

    test "pure without fulltext", %{fetcher: fetcher}  do
      pure_doc_no_fulltext = SolrDoc.new(%{"source_type_ss" => ["research"]})
      decision = AccessDecider.create_update(pure_doc_no_fulltext, fetcher)
      assert [] == decision.fulltext_access
      assert "none" == decision.fulltext_info
    end

    test "sorbit thesis with url should be open access", %{fetcher: fetcher} do 
      sorbit_doc = %SolrDoc{format: "thesis", source_ss: ["sorbit"], fulltext_list_ssf: ["{\"source\":\"sorbit\",\"local\":true,\"type\":\"other\",\"url\":\"http://production.datastore.cvt.dk/filestore?oid=5795f17d6bbf232e70000a6e&targetid=5795f17d6bbf232e70000a71\"}"], holdings_ssf: nil, id: "202295716"}
      decision = AccessDecider.create_update(sorbit_doc, fetcher)
      assert ["dtupub", "dtu"] == decision.fulltext_access
      assert "metastore" == decision.fulltext_info
    end
    test "sorbit thesis without url should not be open access", %{fetcher: fetcher} do 
      sorbit_doc = %SolrDoc{format: "thesis", source_ss: ["sorbit"], fulltext_list_ssf: ["{\"source\":\"sorbit\",\"local\":true,\"type\":\"other\"}"], holdings_ssf: nil, id: "202295716"}
      decision = AccessDecider.create_update(sorbit_doc, fetcher)
      refute ["dtupub", "dtu"] == decision.fulltext_access
      refute "pure" == decision.fulltext_info
    end
  end

  describe "sfx_fulltext\3" do
    test "with an empty journal" do
      assert nil == AccessDecider.sfx_fulltext(%SolrDoc{}, :bla, %SolrJournal{})
    end
    test "with a valid sfx holding" do
      pest_journal = %SolrJournal{embargo_ssf: nil,
 holdings_ssf: ["{\"fromissue\":\"1\",\"source\":\"jnl_sfx\",\"fromvolume\":\"56\",\"fromyear\":\"2000\",\"type\":\"electronic\"}"],
 issn_ss: ["15264998", "1526498x"],
 title_ts: ["Pest management science", "PEST MANAGE SCI"]}
      pest_article = %SolrDoc{pub_date_tis: [2016]}
      refute nil == AccessDecider.sfx_fulltext(pest_article, :bla, pest_journal)
    end
  end
end
