defmodule MetastoreUpdaterTest do
  use ExUnit.Case

  @update1 MetastoreUpdate.new(%{id: "1937", fulltext_access: ["dtu", "dtupub"], fulltext_info: "metastore"})
  @update2 MetastoreUpdate.new(%{id: "1938", fulltext_access: ["dtu"], fulltext_info: "sfx"})

  test "create_updates" do
    updates = MetastoreUpdater.create_updates([@update1, @update2])
    assert is_list(updates)
  end

  test "create_update" do
     update = MetastoreUpdater.create_update(@update1)
     assert update == %{
       "id" => "1937",
       "fulltext_availability_ss" => %{"set" => ["dtu", "dtupub"]},
       "fulltext_info_ss" => %{"set" => "metastore"}
     }
  end
end
