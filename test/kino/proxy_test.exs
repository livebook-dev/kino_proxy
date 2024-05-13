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

  test "returns the peer data" do
    Kino.Proxy.listen(fn conn ->
      assert get_peer_data(conn) == %{
               port: 111_317,
               address: {127, 0, 0, 1},
               ssl_cert: nil
             }

      send_resp(conn, 200, "it works!")
    end)

    conn = conn(:get, "/123/proxy/")
    run_endpoint(conn)

    assert_receive {_ref, {200, _headers, "it works!"}}
  end

  test "returns the http protocol" do
    Kino.Proxy.listen(fn conn ->
      assert get_http_protocol(conn) == :"HTTP/1.1"
      send_resp(conn, 200, "it works!")
    end)

    conn = conn(:get, "/123/proxy/")
    run_endpoint(conn)

    assert_receive {_ref, {200, _headers, "it works!"}}
  end

  test "reads the body" do
    body = :crypto.strong_rand_bytes(20 * 1024 * 1024)

    Kino.Proxy.listen(fn conn ->
      stream =
        Stream.resource(
          fn -> {conn, 0} end,
          fn
            {:halt, acc} ->
              {:halt, acc}

            {conn, count} ->
              case read_body(conn) do
                {:ok, body, conn} ->
                  count = count + byte_size(body)
                  {[body], {:halt, {conn, count}}}

                {:more, body, conn} ->
                  count = count + byte_size(body)
                  {[body], {conn, count}}
              end
          end,
          fn {result, _count} -> result end
        )

      assert Enum.join(stream) == body
      send_resp(conn, 200, body)
    end)

    conn = conn(:get, "/123/proxy/", body)
    run_endpoint(conn)

    assert_receive {_ref, {200, _headers, ^body}}
  end

  test "sends chunked response" do
    Kino.Proxy.listen(fn conn ->
      conn
      |> send_chunked(200)
      |> chunk("ABC")
    end)

    conn = conn(:get, "/123/proxy/")
    run_endpoint(conn)

    assert_receive {_ref, {200, _headers, "it works!"}}
  end

  defp run_endpoint(conn, opts \\ []) do
    KinoProxy.Endpoint.call(conn, opts)
  end
end
