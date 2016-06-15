defmodule SolrDocTest do
  use ExUnit.Case
  setup do
    doc = %{"_version_" => 1535294313411379200, "abstract_ts" => ["In this paper we present an alternative viewpoint on recent studies of regularity of solutions to the Navier-Stokes equations in critical spaces. In particular, we prove that mild solutions which remain bounded in the space $\\dot H^{1/2}$ do not become singular in finite time, a result which was proved in a more general setting by L. Escauriaza, G. Seregin and V. Sverak using a different approach. We use the method of \"concentration-compactness\" + \"rigidity theorem\" which was recently developed by C. Kenig and F. Merle to treat critical dispersive equations. To the authors' knowledge, this is the first instance in which this method has been applied to a parabolic equation. We remark that we have restricted our attention to a special case due only to a technical restriction, and plan to return to the general case (the $L^3$ setting) in a future publication.", "Comment: 41 pages"], "access_ss" => ["dtupub", "dtu"], "alert_timestamp_dt" => "2015-10-22T12:11:45.753Z", "author_facet" => ["Kenig, Carlos E.", "Koch, Gabriel S."], "author_ts" => ["Kenig, Carlos E.", "Koch, Gabriel S."],  "cluster_id_ss" => ["2842957"], "format" => "article", "fulltext_availability_ss" => ["UNDETERMINED"], "fulltext_list_ssf" => ["{\"source\":\"arxiv\",\"local\":false,\"type\":\"other\",\"url\":\"http://arxiv.org/abs/0908.3349\"}"], "id" => "0", "keywords_facet" => ["Mathematics - Analysis of PDEs"], "keywords_ts" => ["Mathematics - Analysis of PDEs"], "member_id_ss" => ["146834317"], "pub_date_tis" => [2009], "source_ext_ss" => ["ds1:arxiv"], "source_id_ss" => ["arxiv:oai:arXiv.org:0908.3349"], "source_ss" => ["arxiv"], "source_type_ss" => ["other"], "title_ts" => ["An alternative approach to regularity for the Navier-Stokes equations in critical spaces"], "update_timestamp_dt" => "2015-10-22T12:11:51.904Z", "~merge_info_sf" => "{\"abstract_ts\":[\"(arxiv,*) / 146834317\"],\"author_sort\":[\"(arxiv,*) / 146834317\"],\"author_ts\":[\"(arxiv,*) / 146834317\"],\"cluster_id_ss\":[\"(arxiv,*) / 146834317\"],\"format\":[\"(arxiv,*) / 146834317\"],\"fulltext_list_ssf\":[\"(arxiv,*) / 146834317\"],\"keywords_ts\":[\"(arxiv,*) / 146834317\"],\"member_id_ss\":[\"(arxiv,*) / 146834317\"],\"pub_date_tis\":[\"(arxiv,*) / 146834317\"],\"pub_date_tsort\":[\"(arxiv,*) / 146834317\"],\"source_ext_ss\":[\"(arxiv,*) / 146834317\"],\"source_id_ss\":[\"(arxiv,*) / 146834317\"],\"source_ss\":[\"(arxiv,*) / 146834317\"],\"source_type_ss\":[\"(arxiv,*) / 146834317\"],\"title_sort\":[\"(arxiv,*) / 146834317\"],\"title_ts\":[\"(arxiv,*) / 146834317\"]}"}
    sd = SolrDoc.new(doc)
    {:ok, solr_doc: sd}
  end

  # http://getit.findit.dtu.dk/resolve?url_ver=Z39.88-2004&url_ctx_fmt=info:ofi/fmt:kev:mtx:ctx&ctx_ver=Z39.88-2004&ctx_tim=2016-06-15T15:26:19+02:00&ctx_id=&ctx_enc=info:ofi/enc:UTF-8&rft.genre=article&rft.atitle=Muon+Track+Matching&rft.au=Benvenuti,++Alberto&rft.date=9910&rft_val_fmt=info:ofi/fmt:kev:mtx:journal&rft_dat={"id":"2151318745"}&rfr_id=info:sid/findit.dtu.dk&req_id=dtu_staff&svc_dat=fulltext&lastEventId=&r=414154239602535
  # url_ver:"Z39.88-2004"
  # url_ctx_fmt:"info:ofi/fmt:kev:mtx:ctx"
  # ctx_ver:"Z39.88-2004"
  # ctx_tim:"2016-06-15T15:26:19+02:00"
  # ctx_id:""
  # ctx_enc:"info:ofi/enc:UTF-8"
  # rft.genre:"article"
  # rft.atitle:"Muon+Track+Matching"
  # rft.au:"Benvenuti,++Alberto"
  # rft.date:"9910"
  # rft_val_fmt:"info:ofi/fmt:kev:mtx:journal"
  # rft_dat:"{"id":"2151318745"}"
  # rfr_id:"info:sid/findit.dtu.dk"
  # req_id:"dtu_staff"
  # svc_dat:"fulltext"
  # lastEventId:""
  # r:"414154239602535"


#   From Toshokan - for articles only
#   field_map = {
#   'rft.au'     => 'author_ts',
#   'rft.atitle' => 'title_ts',
#   'rft.jtitle' => 'journal_title_ts',
#   'rft.btitle' => 'title_ts',
#   'rft.issn'   => 'issn_ss',
#   'rft.year'   => 'pub_date_tis',
#   'rft.date'   => 'pub_date_tis',
#   'rft.volume' => 'journal_vol_ssf',
#   'rft.issue'  => 'journal_issue_ssf',
#   'rft.pages'  => 'journal_page_ssf',
#   'rft.spage'  => 'journal_page_ssf',
#   'rft.epage'  => 'journal_page_ssf',
#   'rft.doi'    => 'doi_ss',
#   'rft.pub'    => 'publisher_ts',
#   'rft.place'  => 'publication_place_ts',
# }
  test "new", %{solr_doc: sd} do
    assert SolrDoc.id(sd) == "2842957"
  end

  test "title", %{solr_doc: sd} do
    assert SolrDoc.title(sd) == "An alternative approach to regularity for the Navier-Stokes equations in critical spaces"
  end

  test "format", %{solr_doc: sd} do
    assert sd.format == "article"
  end
end
