defmodule OpenUrlTest do
  use ExUnit.Case

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
    IO.puts ou_str
    assert String.contains?(ou_str, "rft.au=Benvenuti%2C+Albert")
  end

end
