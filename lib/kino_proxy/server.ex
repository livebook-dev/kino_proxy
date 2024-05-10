defmodule KinoProxy.Server do
  # TODO: Add doc comments
  @moduledoc false

  @proxy_params ["id", "path"]

  def run(pid, %Plug.Conn{params: %{"path" => path_info}} = conn) when is_pid(pid) do
    # TODO: We don't want to pass the whole connection
    # but only certain fields, and then rebuild it on the client
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
    loop(monitor_ref, conn)
  end

  defp loop(monitor_ref, conn) do
    receive do
      {:send_resp, pid, ref, status, headers, body} ->
        conn = Plug.Conn.send_resp(%{conn | resp_headers: headers}, status, body)
        send(pid, {ref, :ok})
        loop(monitor_ref, conn)

      {:DOWN, ^monitor_ref, :process, _pid, reason} ->
        {conn, reason}
    end
  end
end
