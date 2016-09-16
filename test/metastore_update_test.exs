defmodule MetastoreUpdateTest do
  use ExUnit.Case, async: true
  test "basic struct" do
    fields = %{id: 12345, fulltext_access: ["dtu"], fulltext_info: "sfx"}
    update = MetastoreUpdate.new(fields)
    assert 12345 == update.id
    assert ["dtu"] == update.fulltext_access
    assert "sfx" == update.fulltext_info
  end
end
