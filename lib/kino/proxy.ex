defmodule Kino.Proxy do
  use GenServer

  @name __MODULE__

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  def request(%Plug.Conn{} = conn) do
    GenServer.call(@name, {:request, conn, self()})
  end

  def listen(fun) when is_function(fun, 1) do
    GenServer.cast(@name, {:listen, fun})
  end

  # GenServer callbacks

  @impl true
  def init(_opts) do
    {:ok, %{fun: nil}}
  end

  @impl true
  def handle_call({:request, conn, pid}, from, state) do
    pid =
      spawn(fn ->
        Process.link(pid)
        conn = put_in(conn.adapter, {KinoProxy.Adapter, pid})
        state.fun.(conn)

        GenServer.reply(from, :ok)
      end)

    {:reply, pid, state}
  end

  @impl true
  def handle_cast({:listen, fun}, state) do
    {:noreply, %{state | fun: fun}}
  end
end
