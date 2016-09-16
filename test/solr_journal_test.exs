defmodule SolrJournalTest do
  use ExUnit.Case, async: true
  doctest SolrJournal

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

  test "holdings default" do
    # If toyear is missing, it should default to the current year
    missing_toyear = SolrJournal.Holdings.from_json([
      "{\"placement\":\"Rijkswaterstaat communications\",\"fromissue\":\"1\",\"fromyear\":\"1959\",\"alis_key\":\"000131534\",\"type\":\"printed\",\"toissue\":\"49\"}"
      ])
    assert missing_toyear.toyear == "2016"
  end

  test "open_access?", %{journal: normal, open_access_journal: oa_journal} do
    assert false == SolrJournal.open_access?(normal)
    assert true == SolrJournal.open_access?(oa_journal)
  end

  describe "within_holdings?" do
    test "when doc is published before holdings", %{journal: journal} do
      before_doc = SolrDoc.new(%{
       "journal_issue_ssf" => ["1"],
       "issn_ss" => ["03702634"],
       "journal_vol_ssf" => ["33"],
       "pub_date_tis" => [1933]
      })
      refute SolrJournal.within_holdings?(journal: journal, article: before_doc)
    end
    test "when doc is published within holdings", %{journal: journal} do
     after_doc = SolrDoc.new(%{
          "journal_issue_ssf" => ["1"],
          "issn_ss" => ["03702634"],
          "journal_vol_ssf" => ["33"],
          "pub_date_tis" => [1956]
        })
      assert SolrJournal.within_holdings?(journal: journal, article: after_doc)
    end
    test "when doc is published in between two holdings periods" do
      complex_holdings = SolrJournal.new(%{
        "holdings_ssf" => [
         "{\"placement\":\"WESCON conference\",\"tovolume\":\"21\",\"fromyear\":\"1977\",\"fromvolume\":\"21\",\"toyear\":\"1977\",\"alis_key\":\"000139306\",\"type\":\"printed\"}",
         "{\"placement\":\"WESCON conference\",\"tovolume\":\"34\",\"fromyear\":\"1979\",\"fromvolume\":\"23\",\"toyear\":\"1990\",\"alis_key\":\"000139306\",\"type\":\"printed\"}"
       ]})
      middle = SolrDoc.new(%{"pub_date_tis" => [1978]})

      refute SolrJournal.within_holdings?(journal: complex_holdings, article: middle)
    end
    test "when doc is has no toyear" do
      missing_toyear = %SolrJournal{holdings_ssf: ["{\"source\":\"jnl_sfx\",\"fromyear\":\"1997\",\"type\":\"electronic\"}"],
   issn_ss: ["15325016", "15325008"],
   title_ts: ["Electric power components and systems",
    "ELECTR POWER COMPON SYST"]}
      within = SolrDoc.new(issn_ss: [15325016], pub_date_tis: [1998])
      assert SolrJournal.within_holdings?(journal: missing_toyear, article: within)
    end
    test "another test case" do
      pest_journal = %SolrJournal{embargo_ssf: nil,
 holdings_ssf: ["{\"fromissue\":\"1\",\"source\":\"jnl_sfx\",\"fromvolume\":\"56\",\"fromyear\":\"2000\",\"type\":\"electronic\"}"],
 issn_ss: ["15264998", "1526498x"],
 title_ts: ["Pest management science", "PEST MANAGE SCI"]}

    pest_article = %SolrDoc{pub_date_tis: [2016]}
    refute SolrJournal.under_embargo?(journal: pest_journal, article: pest_article) 
    assert SolrJournal.within_holdings?(journal: pest_journal, article: pest_article) 
    end
  end
  describe "year_range" do
    # Sometimes fromyear is missing - this is caused by a user error when entering data in SFX
    test "replaces missing fromyear with toyear" do
      missing_fromyear = %SolrJournal{holdings_ssf: ["{\"tovolume\":\"96\",\"source\":\"jnl_sfx\",\"toyear\":\"2008\",\"type\":\"electronic\",\"toissue\":\"4\"}"], issn_ss: ["00168092"], title_ts: ["Georgetown Law Journal", "GEORGETOWN LAW J"]}
      holdings = missing_fromyear.holdings_ssf |> SolrJournal.Holdings.from_json
      assert 2008..2008 == SolrJournal.Holdings.year_range(holdings)
    end
  end

  describe "valid?" do
    test "without holdings should be false" do
      no_holdings = %SolrJournal{title_ts: ["No Holdings"]}
      refute SolrJournal.valid?(no_holdings)
    end
    test "without a from year should be false" do
      missing_fromyear = %SolrJournal{holdings_ssf: ["{\"tovolume\":\"96\",\"source\":\"jnl_sfx\",\"toyear\":\"2008\",\"type\":\"electronic\",\"toissue\":\"4\"}"], issn_ss: ["00168092"], title_ts: ["Georgetown Law Journal", "GEORGETOWN LAW J"]}
      refute SolrJournal.valid?(missing_fromyear)
    end
    test "with a from year should be true", %{journal: normal} do
      assert SolrJournal.valid? normal
    end  
  end
  describe "embargo/1" do
    test "it returns value from embargo_ssf" do
      assert 256 == SolrJournal.embargo(%SolrJournal{embargo_ssf: ["256"]})
    end
    test "it returns 0 if the number is missing" do
      assert 0 == SolrJournal.embargo(%SolrJournal{})
    end
    test "it returns 0 if the number is a blank array" do
      assert 0 == SolrJournal.embargo(%SolrJournal{embargo_ssf: []})
    end
  end
  describe "identifiers\1" do
    test "with two issns" do
      assert ["issn_ss:12345678", "issn_ss:98765432"] == SolrJournal.identifiers(%SolrJournal{issn_ss: ["12345678", "98765432"]})
    end
  end
end
