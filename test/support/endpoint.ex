defmodule KinoProxy.Endpoint do
  use Plug.Router

  plug :match

  plug Plug.RequestId

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason

  plug Plug.MethodOverride
  plug Plug.Head

  plug Plug.Session,
    store: :cookie,
    key: "lb_session",
    signing_salt: "deadbook"

  plug :fetch_session
  plug :dispatch

  match "/:id/proxy/*path" do
    if pid = GenServer.whereis(Kino.Proxy) do
      {conn, _reason} = Kino.Proxy.run(pid, conn)
      conn
    else
      json = Jason.encode!(%{error: %{details: "Not Found"}})
      Plug.Conn.send_resp(conn, 404, json)
    end
  end

  def fetch_query_string(conn, _opts) do
    Plug.Conn.fetch_query_params(conn)
  end

  def fetch_req_cookies(conn, _opts) do
    Plug.Conn.fetch_cookies(conn)
  end

  def fetch_req_session(conn, _opts) do
    Plug.Conn.fetch_session(conn)
  end
end
