defmodule SFXInstitutionHoldingsTest do

  use ExUnit.Case

  test "Fetch returns a path to an unzipped xml file" do
    path = HoldingsApi.fetch
    assert File.exists?(path)
    {:ok, xml} = File.read(path)
    assert well_formed(xml)
  end

  test "parse" do
    # it should create a map of identifiers and coverage date
    map = HoldingsApi.parse("test/fixtures/institutional_holding.xml")
    assert Map.get(map, "0036-1399") == [from: {"1997", "57", "1"}, to: {"", "", ""}]
  end

  test "get_best_identifer" do
    # when there is an issn take that
    item = "<item>
    <sfx_id>954925442611</sfx_id>
     <issn>0036-1399</issn>
     <eissn>1095-712X</eissn></item>"
     assert HoldingsApi.get_best_identifier(item) == "0036-1399"

     # when there is only an eissn take that
     item = "<item>
     <sfx_id>954925442611</sfx_id>
     <eissn>1095-712X</eissn></item>"
     assert HoldingsApi.get_best_identifier(item) == "1095-712X"

     # if there is an isbn take that
     item = "<item>
     <sfx_id>954925442611</sfx_id>
     <isbn>0-309-02233-9</isbn></item>"
      assert HoldingsApi.get_best_identifier(item) == "0-309-02233-9"
  end


  def well_formed(xml) do
    try do
      xml |> SweetXml.parse
      true
    catch
      :exit, _ -> false
    end
  end

end
