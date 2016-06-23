defmodule SFXInstitutionHoldingsTest do

  use ExUnit.Case

  test "It returns a path to an unzipped xml file" do
    path = HoldingsApi.fetch
    assert File.exists?(path)
    {:ok, xml} = File.read(path)
    assert well_formed(xml)
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
