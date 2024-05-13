defmodule Kino.ProxyTest do
  use ExUnit.Case, async: true
  use Plug.Test

  test "returns the user-defined response" do
    Kino.Proxy.listen(fn conn ->
      assert get_req_header(conn, "x-auth-token") == ["foo-bar"]
      assert conn.request_path == "/foo/bar"

      conn
      |> put_resp_header("content-type", "text/plain")
      |> send_resp(200, "it works!")
    end)

    conn(:get, "/123/proxy/foo/bar")
    |> put_req_header("x-auth-token", "foo-bar")
    |> run_endpoint()

    assert_receive {_ref, {200, _headers, "it works!"}}
  end

  defp run_endpoint(conn, opts \\ []) do
    KinoProxy.Endpoint.call(conn, opts)
  end
end
