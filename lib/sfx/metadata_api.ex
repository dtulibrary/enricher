defmodule HoldingsMetadataApi do

  @metadata_url "http://sfx.cvt.dk/sfx_local/cgi/public/get_file_metadata.cgi?file=institutional_holding"

  def body do
    {:ok, response} = HTTPoison.get(@metadata_url)
    response.body
  end

  # API mock
  defmodule Test do
    def body do
      "<file_metadata_API><file><status>success</status><file_name>%2Fexlibris%2Fsfx_ver%2Fsfx4_1%2Fsfxlcl41%2Fexport%2Finstitutional_holding.xml</file_name><file_size>96398604</file_size><size_scale>Byte</size_scale><creation_date>20160620</creation_date></file></file_metadata_API>\n"
    end
  end
end
