defmodule SolrDoc do
  defstruct [:cluster_id_ss, :title_ts, :format]
  use ExConstructor

  def id(doc), do: hd(doc.cluster_id_ss)

  def title(doc), do: hd(doc.title_ts)
end
