defmodule Stack do
  use GenServer

  ## Client API ##

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def push(server, elem) do
    GenServer.cast(server, {:push, elem})
  end

  def pop(server) do
    GenServer.call(server, {:pop})
  end

  def batch_pop(server, n) do
    1..n
    |> Enum.map(fn(x) -> GenServer.call(server, {:pop}) end)
    |> Enum.reject(&is_nil/1)
  end

  ## Server Callbacks ##

  def init(:ok) do
    {:ok, []}
  end

  def handle_call({:pop}, _from, [top | rest]) do
    {:reply, top, rest }
  end

  def handle_call({:pop}, _from, []) do
    {:reply, nil, []}
  end

  def handle_cast({:push, elem}, list) do
    {:noreply, [elem | list]}
  end
end
