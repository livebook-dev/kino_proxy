defmodule KinoProxy.Client do
  @moduledoc false
  # The KinoProxy client-side.
  #
  # It controls how the user wants to handle
  # then incoming HTTP request with given `Plug.Conn`.
  #
  # It'll return the `Plug.Conn` that will be shown
  # by the owner of the HTTP request.

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def listen(fun) when is_function(fun, 1) do
    GenServer.cast(partition_name(), {:listen, fun})
  end

  def get_pid() do
    GenServer.whereis(partition_name())
  end

  # GenServer callbacks

  @impl true
  def init(_opts) do
    {:ok, %{fun: nil}}
  end

  @impl true
  def handle_call({:request, data, pid}, _from, state) do
    pid =
      spawn(fn ->
        Process.link(pid)
        ref = Process.monitor(pid)
        conn = struct!(Plug.Conn, %{data | adapter: {KinoProxy.Adapter, {pid, ref}}})
        state.fun.(conn)
      end)

    {:reply, pid, state}
  end

  @impl true
  def handle_cast({:listen, fun}, state) do
    {:noreply, %{state | fun: fun}}
  end

  defp partition_name() do
    {:via, PartitionSupervisor, {KinoProxy.PartitionSupervisor, Kino.Proxy}}
  end
end
