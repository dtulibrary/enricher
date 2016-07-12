defmodule Queue do
  use GenServer

  ## Client API ##

  def start_link(state \\ [], opts \\ []) do
    GenServer.start_link(__MODULE__, state, opts)
  end

  def init(state), do: {:ok, state}

  def enqueue(server, value), do: GenServer.cast(server, {:enqueue, value})
  def dequeue(server), do: GenServer.call(server,:dequeue)

  def batch(server, n) do
    batch = 1..n
    |> Enum.map(fn(x) -> GenServer.call(server, :dequeue) end)
    |> Enum.reject(&is_nil/1)
    # We will not return a batch with both :halt and updates
    # Only updates or [:halt]
    cond do
      batch == [:halt] ->
        batch
      Enum.member?(batch, :halt) ->
        GenServer.cast(server, {:enqueue, :halt})
        Enum.reject(batch, &(&1 == :halt))
      true ->
        batch
    end
  end



  ## Server API ##

  def handle_call(:dequeue, _from, [value|state]) do
    {:reply, value, state}
  end

  def handle_call(:dequeue, _from, []) do
    {:reply, nil, []}
  end

  def handle_cast({:enqueue, value}, state) do
    {:noreply, state ++ [value]}
  end


end
