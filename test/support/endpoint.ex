defmodule KinoProxy.Endpoint do
  use Plug.Router

  plug :match

  plug Plug.RequestId

  plug :dispatch

  match "/:id/proxy/*proxied_path" do
    %{path_info: [id, "proxy" | path_info]} = conn

    script_name = [id, "proxy"]
    conn = %{conn | path_info: path_info, script_name: conn.script_name ++ script_name}

    if pid = GenServer.whereis(Kino.Proxy) do
      {conn, _reason} = Kino.Proxy.serve(pid, conn)
      conn
    else
      json = Jason.encode!(%{error: %{details: "Not Found"}})
      Plug.Conn.send_resp(conn, 404, json)
    end
  end
end
