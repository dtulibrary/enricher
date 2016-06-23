defmodule SFXHoldingsTest do
  use ExUnit.Case

  test "it parses the xml response" do
    sample_xml = HoldingsMetadataApi.Test.body
    assert HoldingsMetadata.parse_creation_date(sample_xml) == {{2016, 6, 20}, {0, 0, 0}}
  end

  test "it returns file mtime" do
    time_now = :calendar.universal_time()
    {:ok, file} = Application.fetch_env(:enricher, :sfx_file_location)
    File.touch(file, time_now)
    assert HoldingsMetadata.file_mtime ==  time_now
  end

  test "update_needed?" do
    # When our test file is very old
    # update_needed? should be true
    fake_file = "tmp/fake_file.xml"
    Application.put_env(:enricher, :sfx_file_location, fake_file)

    old_time = {{1990, 6, 12}, {21, 33, 59}}
    File.touch(fake_file, old_time)
    assert HoldingsMetadata.update_needed? == true
    File.rm(fake_file)

    # When our test file has just been changed
    # update_needed? should be false
    time_now = :calendar.universal_time()
    File.touch(fake_file, time_now)
    assert HoldingsMetadata.update_needed? == false
    File.rm(fake_file)

    # When our test file doesn't exist
    # update_needed? should be true
    assert HoldingsMetadata.update_needed? == true
  end
end
