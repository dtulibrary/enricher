defmodule Enricher.LogServer do
  use GenServer
  
  def start_link(name \\ nil) do
    GenServer.start_link(__MODULE__, [], [name: name])
  end

  def log(pid, msg) do
    GenServer.call(pid, {:log, msg}) 
  end

  def flush_log(pid) do
    GenServer.call(pid, :flush_log)
  end
  
  def messages(pid) do
    GenServer.call(pid, :messages)
  end

  def last_message(pid) do
    messages(pid) |> get_last
  end

  defp get_last([]), do: nil
  defp get_last([msg]), do: msg
  defp get_last([msg | _]), do: msg

  def init(_args) do
    {:ok, []}
  end

  def handle_call({:log, msg}, _from, messages) do
    {:reply, :ok, [msg] ++ messages}
  end

  def handle_call(:messages, _from, messages) do
    {:reply, messages, messages}
  end

  def handle_call(:flush_log, _from, _messages) do
    {:reply, :ok, []}
  end
end
