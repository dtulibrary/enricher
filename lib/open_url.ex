defmodule OpenUrl do
  defstruct [
    :au, :atitle, :jtitle, :btitle,
    :issn, :year, :date, :volume, :issue,
    :pages, :spage, :epage,
    :doi, :pub, :place, :genre, :id
  ]
  use ExConstructor

  def map(ou) do
    Map.merge(defaults, rft_data(ou))
  end

  def to_uri(ou) do
    URI.encode_query(map(ou))
  end

  @doc "Get rid of nil values and correct key names"
  def rft_data(ou) do
     Map.from_struct(ou)
     |> Map.delete(:id)
     |> Enum.reject(fn {x, y} -> is_nil(y) end)
     |> Enum.into(Map.new, fn {x, y} -> {"rft.#{x}", y} end)
     |> Map.merge(special_data(ou))
  end

  # This element is for non Open URL user supplied data
  def special_data(ou) do
    %{"rft_dat" => "{\"id\": \"#{ou.id}\"}"}
  end

  def defaults do
    {{year, month, day}, {hour, minute, second}} = :calendar.universal_time()
    # ISO8601 - trailing Z for UTC
    time = "#{year}-#{month}-#{day}T#{hour}:#{minute}:#{second}Z"
    %{
      "url_ver" => "Z39.88-2004",
      "url_ctx_fmt" => "info:ofi/fmt:kev:mtx:ctx",
      "ctx_ver" => "Z39.88-2004",
      "ctx_tim" => time,
      "ctx_enc" => "info:ofi/enc:UTF-8",
      "svc_dat" => "fulltext",
      "rft_id" => "info:sid/findit.dtu.dk:MetastoreEnricher"
    }
  end
end
