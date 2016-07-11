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
    1..n
    |> Enum.map(fn(x) -> GenServer.call(server, :dequeue) end)
    |> Enum.reject(&is_nil/1)
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
