defmodule KinoProxy.Server do
  # TODO: Add doc comments
  @moduledoc false

  @proxy_params ["id", "path"]

  def run(pid, %Plug.Conn{params: %{"path" => path_info}} = conn) when is_pid(pid) do
    # TODO: We don't want to pass the whole connection
    # but only certain fields, and then rebuild it on the client
    {mod, state} = conn.adapter
    %{plug_session: session_data} = conn.private
    request_path = "/" <> Enum.join(path_info, "/")
    private = %{plug_session: session_data}
    params = Map.drop(conn.params, @proxy_params)
    path_params = Map.drop(conn.path_params, @proxy_params)

    conn = %{
      conn
      | request_path: request_path,
        path_info: path_info,
        params: params,
        path_params: path_params,
        private: private
    }

    spawn_pid = GenServer.call(pid, {:request, conn, self()})
    monitor_ref = Process.monitor(spawn_pid)
    loop(spawn_pid, monitor_ref, mod, state)
  end

  defp loop(spawn_pid, monitor_ref, mod, state) do
    receive do
      {:send_resp, pid, ref, args} ->
        {:ok, _body, state} = apply(mod, :send_resp, [state | args])
        send(pid, {ref, :ok})
        loop(spawn_pid, monitor_ref, mod, state)

      {:DOWN, ^monitor_ref, :process, _, reason} ->
        reason
    end
  end
end
