defmodule KinoProxy.Server do
  # TODO: Add doc comments
  @moduledoc false

  import Plug.Conn

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
        conn = send_resp(%{conn | resp_headers: headers}, status, body)
        send(pid, {ref, :ok})
        loop(monitor_ref, conn)

      {:get_peer_data, pid, ref} ->
        send(pid, {ref, get_peer_data(conn)})
        loop(monitor_ref, conn)

      {:get_http_protocol, pid, ref} ->
        send(pid, {ref, get_http_protocol(conn)})
        loop(monitor_ref, conn)

      {:read_req_body, pid, ref, opts} ->
        {message, conn} =
          case read_body(conn, opts) do
            {:ok, data, conn} -> {{:ok, data}, conn}
            {:more, data, conn} -> {{:more, data}, conn}
            {:error, _} = error -> {error, conn}
          end

        send(pid, {ref, message})
        loop(monitor_ref, conn)

      {:send_chunked, pid, ref, status, headers} ->
        conn = send_chunked(%{conn | resp_headers: headers}, status)
        send(pid, {ref, :ok})
        loop(monitor_ref, conn)

      {:chunk, pid, ref, chunk} ->
        {message, conn} =
          case chunk(conn, chunk) do
            {:error, _} = error -> {error, conn}
            result -> result
          end

        send(pid, {ref, message})
        loop(monitor_ref, conn)

      {:DOWN, ^monitor_ref, :process, _pid, reason} ->
        {conn, reason}
    end
  end
end
