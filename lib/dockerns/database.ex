defmodule Dockerns.Database do
  use GenServer

  @interval 30_000

  def start_link(sock) do
    GenServer.start_link(__MODULE__, sock, name: __MODULE__)
  end

  def init(sock) do
    database = Dockerns.Refresh.refresh(sock)
    Process.send_after(self(), :refresh, @interval)
    {:ok, %{sock: sock, database: database}}
  end

  def get_a(name) when is_binary(name) do
    GenServer.call(__MODULE__, {:get_a, name})
  end

  def handle_call({:get_a, name}, _, state = %{database: database}) do
    result = Map.get(database, name)
    {:reply, result, state}
  end

  def handle_info(:refresh, state = %{sock: sock}) do
    database = Dockerns.Refresh.refresh(sock)
    Process.send_after(self(), :refresh, @interval)
    {:noreply, %{state | database: database}}
  end
end
