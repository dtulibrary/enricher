defmodule OpenUrlTest do
  use ExUnit.Case

  ##################### EXAMPLE OF OPEN URL for article ##########################
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

  ##################### EXAMPLE OF OPEN URL for book (URL encoded) ##########################
  # url_ver=Z39.88-2004
  # url_ctx_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Actx
  # ctx_ver=Z39.88-2004
  # ctx_tim=2016-06-16T14%3A31%3A22%2B02%3A00
  # ctx_id=
  # ctx_enc=info%3Aofi%2Fenc%3AUTF-8
  # rft.genre=book
  # rft.btitle=Integrative+human+biochemistry
  # rft.pub=Springer
  # rft.au=Castanho%2C+Miguel+A.+R.+B.
  # rft.spage=1+online+resource
  # rft.date=2018
  # rft.isbn=9781493930579
  # rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Abook
  # rft_id=urn%3Aisbn%3A1493930583
  # rft_id=urn%3Aisbn%3A1493930575
  # rft_id=urn%3Aisbn%3A9781493930586
  # rft_id=urn%3Aisbn%3A9781493930579
  # rft_dat=%7B%22id%22%3A%22277030343%22%7D
  # rfr_id=info%3Asid%2Ffindit.dtu.dk
  # req_id=dtu_staff
  # svc_dat=fulltext
  # lastEventId=
  # r=540858746512246

  setup do
    fields = %{
      atitle: "Muon Track Matching",
      au: "Benvenuti, Alberto",
      genre: "article",
      id: "2151318745"
    }
    {:ok, open_url: OpenUrl.new(fields)}
  end
  test "constructor", %{open_url: open_url} do
    assert open_url.atitle == "Muon Track Matching"
  end

  test "map", %{open_url: open_url} do
    map = OpenUrl.map(open_url)
    assert map["rft.au"] == "Benvenuti, Alberto"
    assert map["ctx_ver"] == "Z39.88-2004"
    assert map["rft_dat"] == "{\"id\": \"2151318745\"}"
  end

  test "rft_data", %{open_url: open_url} do
    data = OpenUrl.rft_data(open_url)
    assert is_map data
    assert data["rft.atitle"] == "Muon Track Matching"
    assert data["rft.genre"] == "article"
  end

  test "to_uri", %{open_url: open_url} do
    ou_str = OpenUrl.to_uri(open_url)
    assert String.contains?(ou_str, "rft.au=Benvenuti%2C+Albert")
  end

end
