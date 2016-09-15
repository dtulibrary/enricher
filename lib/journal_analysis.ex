defmodule Mix.Tasks.CheckJournals do
  @shortdoc "Check SFX journals for data errors"
  use Mix.Task

  def setup, do: {:ok, _started} = Application.ensure_all_started(:httpoison)
  def run(_args) do
    setup
    SolrClient.all_journals
    |> Enum.each(fn(j) -> 
     unless SolrJournal.valid?(j) do
       Mix.shell.error SolrJournal.invalid_message(j)
     end
    end)
  end
end
