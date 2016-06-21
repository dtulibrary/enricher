defmodule QueryGetitTest do
  use ExUnit.Case

  test "url" do
    assert QueryGetit.url == "http://localhost:3000?resolve" 
  end
end
