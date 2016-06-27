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
    # map = HoldingsApi.parse("tmp/institutional_holding.xml.real")
    map = HoldingsApi.parse("test/fixtures/institutional_holding.xml")
    assert Map.get(map, "0036-1399") == [from: {"1966", "14", "1"}, to: {"", "", ""}]
  end

  test "parse_section" do
    # it should take the oldest from
    item = "<item>
      <sfx_id>954925442611</sfx_id>
      <object_type>JOURNAL</object_type>
      <title>SIAM journal on applied mathematics</title>
      <title>SIAM J APPL MATH</title>
      <title>SIAM J A MA</title>
      <issn>0036-1399</issn>
      <eissn>1095-712X</eissn>
      <coverage>
       <from>
        <year>1966</year>
        <volume>14</volume>
        <issue>1</issue>
       </from>
       <to></to>
       <embargo>
        <days_not_available>2190</days_not_available>
       </embargo>
      </coverage>
      <coverage>
       <from>
        <year>1997</year>
        <volume>57</volume>
        <issue>1</issue>
       </from>
       <to></to>
      </coverage>
     </item>"
     from = HoldingsApi.parse_section(item, "from")
     assert from == {"1966", "14", "1"}
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

      # if there is no identifier
      item = "<item></item>"
      assert HoldingsApi.get_best_identifier(item) == "UNDEFINED"
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
