defmodule KinoProxy.Plug do
  use Plug.Builder

  def init(opts), do: opts

  def call(conn, _opts) do
    if pid = GenServer.whereis(Kino.Proxy) do
      Kino.Proxy.run(pid, conn)
      conn
    else
      json = Jason.encode!(%{error: %{details: "Not Found"}})
      Plug.Conn.send_resp(conn, 404, json)
    end
  end
end
