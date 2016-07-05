defmodule SolrJournalTest do
  use ExUnit.Case

  setup do
    journal = SolrJournal.new(%{
       "_version_" => 1529502580976123905,
       "access_ss" => ["dtupub", "dtu"],
       "affiliation_associations_json" => "{\"editor\":[],\"supervisor\":[],\"author\":[]}",
       "alert_timestamp_dt" => "2012-11-09T14:17:55.467Z",
       "alis_key_ssf" => ["000132324"], "cluster_id_ss" => ["320735441"],
       "format" => "journal", "fulltext_availability_ss" => ["UNDETERMINED"],
       "holdings_ssf" => ["{\"tovolume\":\"62\",\"fromyear\":\"1947\",\"fromvolume\":\"42\",\"toyear\":\"1967\",\"alis_key\":\"000132324\",\"type\":\"printed\"}"],
       "id" => "1392610167", "issn_ss" => ["03702634"],
       "journal_title_facet" => ["Power and works engineering"],
       "journal_title_ts" => ["Power and works engineering"],
       "member_id_ss" => ["409670022", "320735441"], "score" => 17.585644,
       "source_ext_ss" => ["ds1:ds1_jnl", "ds1:jnl_alis"],
       "source_id_ss" => ["ds1_jnl:582772", "jnl_alis:000132324"],
       "source_ss" => ["ds1_jnl", "jnl_alis"], "source_type_ss" => ["other"],
       "timestamp" => "2016-03-22T11:48:48.353Z",
       "title_ts" => ["Power and works engineering"],
       "udc_ss" => ["621.3", "621", "620.4", "(410)", "(05)"],
       "update_timestamp_dt" => "2014-03-08T19:48:57.715Z"}
   )
   oa_journal = SolrJournal.new(%{
      "access_ss" => [
        "dtupub",
        "dtu"
      ],
      "alert_timestamp_dt" => "2014-04-30T00:11:16.318Z",
      "journal_title_ts" => ["Angiology: open access"],
      "journal_title_facet" => ["Angiology: open access"],
      "member_id_ss" => ["450146575"],
      "title_ts" => ["Angiology: Open Access"],
      "source_ss" => ["ds1_jnl"],
      "format" => "journal",
      "update_timestamp_dt" => "2014-04-30T02:52:47.771Z",
      "issn_ss" => ["23299495"],
      "fulltext_availability_ss" => ["UNDETERMINED"],
      "source_id_ss" => ["ds1_jnl:917610"],
      "cluster_id_ss" => ["450146575"],
      "source_ext_ss" => ["ds1:ds1_jnl"],
      "source_type_ss" => ["other"],
      "affiliation_associations_json" => "{\"editor\":[],\"supervisor\":[],\"author\":[]}",
      "id" => "1392668485",
      "_version_" => 1529502585864585200,
      "timestamp" => "2016-03-22T11:48:53.013Z",
      "score" => 3.9233332
    })
   {:ok, journal: journal, open_access_journal: oa_journal}
  end

  test "holdings", %{journal: journal} do
    details = [from: {"1947", "42", ""}, to: {"1967", "62", ""}, embargo: 0]
    assert SolrJournal.holdings(journal) == details

    # try with some other values
    different_holdings = SolrJournal.new(%{"holdings_ssf": [
      "{\"placement\":\"Rijkswaterstaat communications\",\"fromissue\":\"1\",\"fromyear\":\"1959\",\"toyear\":\"1991\",\"alis_key\":\"000131534\",\"type\":\"printed\",\"toissue\":\"49\"}"
      ]})
    assert SolrJournal.holdings(different_holdings) ==  [from: {"1959", "", "1"}, to: {"1991", "", "49"}, embargo: 0]

    ## When there is no holding information

    assert SolrJournal.holdings(SolrJournal.new(%{})) == "NONE"

    ## When there are multiple holdings entries

    multiple = SolrJournal.new(%{holdings_ssf: ["{\"placement\":\"Academia Scientiarum\",\"tovolume\":\"7\",\"fromyear\":\"1975\",\"fromvolume\":\"1\",\"toyear\":\"1982\",\"alis_key\":\"000127127\",\"type\":\"printed\"}", "{\"placement\":\"Academia Scientiarum\",\"fromissue\":\"1\",\"fromyear\":\"1941\",\"toyear\":\"1975\",\"alis_key\":\"000127127\",\"type\":\"printed\",\"toissue\":\"600\"}"]})
    assert is_list(SolrJournal.holdings(multiple))
  end

  test "open_access?", %{journal: normal, open_access_journal: oa_journal} do
    assert false == SolrJournal.open_access?(normal)
    assert true == SolrJournal.open_access?(oa_journal)
  end

  test "within_holdings?", %{journal: journal} do
    before_doc = SolrDoc.new(%{
     "journal_issue_ssf" => ["1"],
     "issn_ss" => ["03702634"],
     "journal_vol_ssf" => ["33"],
     "pub_date_tis" => [1933]
   })
   refute SolrJournal.within_holdings?(journal: journal, article: before_doc)
   after_doc = SolrDoc.new(%{
        "journal_issue_ssf" => ["1"],
        "issn_ss" => ["03702634"],
        "journal_vol_ssf" => ["33"],
        "pub_date_tis" => [1956]
      })
    assert SolrJournal.within_holdings?(journal: journal, article: after_doc)

    complex_holdings = SolrJournal.new(%{
      "holdings_ssf" => [
       "{\"placement\":\"WESCON conference\",\"tovolume\":\"21\",\"fromyear\":\"1977\",\"fromvolume\":\"21\",\"toyear\":\"1977\",\"alis_key\":\"000139306\",\"type\":\"printed\"}",
       "{\"placement\":\"WESCON conference\",\"tovolume\":\"34\",\"fromyear\":\"1979\",\"fromvolume\":\"23\",\"toyear\":\"1990\",\"alis_key\":\"000139306\",\"type\":\"printed\"}"
     ]})
    middle = SolrDoc.new(%{"pub_date_tis" => [1978]})
    refute SolrJournal.within_holdings?(journal: complex_holdings, article: middle)
  end

end
