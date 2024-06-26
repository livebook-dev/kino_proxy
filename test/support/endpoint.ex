defmodule KinoProxy.Endpoint do
  use Plug.Router, copy_opts_to_assign: :test

  plug :match

  plug Plug.RequestId

  plug :dispatch

  match "/:id/proxy/*proxied_path" do
    %{path_info: [id, "proxy" | path_info]} = conn

    script_name = [id, "proxy"]
    conn = %{conn | path_info: path_info, script_name: conn.script_name ++ script_name}

    if pid = KinoProxy.Client.get_pid(conn.assigns.test, self()) do
      {conn, _reason} = KinoProxy.Server.serve(pid, conn.assigns.test, conn)
      conn
    else
      json = Jason.encode!(%{error: %{details: "Not Found"}})
      Plug.Conn.send_resp(conn, 404, json)
    end
  end
end
