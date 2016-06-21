defmodule QueryGetit do
  def url do
    Application.get_env(:enricher, :getit_url) 
  end
end
