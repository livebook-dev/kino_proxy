defmodule Kino.ProxyTest do
  use ExUnit.Case, async: true

  setup do
    pid = start_supervised!({Bandit, plug: KinoProxy.Endpoint, scheme: :http, port: 0})
    {:ok, {_address, port}} = ThousandIsland.listener_info(pid)
    req = Req.new(base_url: "http://localhost:#{port}", retry: false)

    {:ok, req: req}
  end

  test "it works", %{req: req} do
    Kino.Proxy.listen(fn conn ->
      # For test assertive purposes
      assert Plug.Conn.get_req_header(conn, "x-auth-token") == ["foo-bar"]
      assert conn.request_path == "/foo/bar"

      conn
      |> Plug.Conn.put_resp_header("content-type", "text/plain")
      |> Plug.Conn.send_resp(200, "it works!")
    end)

    response =
      Req.get!(req,
        url: "/123/proxy/foo/bar",
        headers: [{"x-auth-token", "foo-bar"}]
      )

    assert response.status == 200
    assert response.body == "it works!"
  end
end
