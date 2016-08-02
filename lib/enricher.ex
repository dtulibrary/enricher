defmodule Enricher do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Queue, [[], [name: :doc_queue]], id: :doc_queue),
      worker(Queue, [[], [name: :update_queue]], id: :update_queue),
      worker(Task, [fn -> MetastoreMaster.add_articles_to_stack(:doc_queue) end], id: :add, restart: :transient),
      worker(Task, [fn -> AccessDecider.process(:doc_queue, :update_queue) end], id: :decide, restart: :transient),
      worker(Task, [fn -> MetastoreUpdater.run(:update_queue) end], id: :update, restart: :transient)
    ]

    opts = [strategy: :one_for_one]
    {:ok, _pid} = Supervisor.start_link(children, opts)
  end
end
