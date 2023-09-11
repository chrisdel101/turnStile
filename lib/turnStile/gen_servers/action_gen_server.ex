defmodule TurnStile.ActionGenServer do
  use GenServer
  alias TurnStile.Patients
  #client

  def start_link(default) when is_binary(default) do
    GenServer.start_link(__MODULE__, default)
  end

  def lookup(pid, name) do
    GenServer.call(pid, {:lookup, name})
  end
  def push(pid, element) do
    GenServer.cast(pid, {:push, element})
  end

  def pop(pid) do
    GenServer.call(pid, :pop)
  end

  # Server

  @impl true
  @spec init(binary) :: {:ok, [binary]}
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:lookup, name}, _from, names) do
    {:reply, Map.fetch(names, name), names}
  end

  @impl true
  def handle_cast({:create, name}, names) do
    if Map.has_key?(names, name) do
      {:noreply, names}
    else
      {:ok, bucket} = KV.Bucket.start_link([])
      {:noreply, Map.put(names, name, bucket)}
    end
  end

  @impl true
  def handle_info(:work, state) do
    # Do the desired work here
    # ...

    # Reschedule once more
    schedule_work()

    {:noreply, state}
  end

  defp schedule_work do
    # We schedule the work to happen in 2 hours (written in milliseconds).
    # Alternatively, one might write :timer.hours(2)
    Process.send_after(self(), :work, 2 * 60 * 60 * 1000)
  end
end
