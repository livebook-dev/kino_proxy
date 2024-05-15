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

    assert %{resp_body: "it works!", status: 200} =
             conn(:get, "/123/proxy/foo/bar")
             |> put_req_header("x-auth-token", "foo-bar")
             |> run_endpoint()
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
    assert %{resp_body: "it works!", status: 200} = run_endpoint(conn)
  end

  test "returns the http protocol" do
    Kino.Proxy.listen(fn conn ->
      assert get_http_protocol(conn) == :"HTTP/1.1"
      send_resp(conn, 200, "it works!")
    end)

    conn = conn(:get, "/123/proxy/")
    assert %{resp_body: "it works!", status: 200} = run_endpoint(conn)
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

    assert %{resp_body: ^body, status: 200} = run_endpoint(conn)
    assert_receive {_ref, {200, _headers, ^body}}
  end

  test "sends chunked response" do
    chunk = :crypto.strong_rand_bytes(10 * 1024 * 1024)
    other_chunk = :crypto.strong_rand_bytes(10 * 1024 * 1024)

    Kino.Proxy.listen(fn conn ->
      conn = send_chunked(conn, 200)
      assert conn.state == :chunked

      {:ok, _conn} = chunk(conn, chunk)
      {:ok, _conn} = chunk(conn, other_chunk)

      conn
    end)

    conn = conn(:get, "/123/proxy/")
    assert %{resp_body: body, status: 200} = run_endpoint(conn)
    assert body == chunk <> other_chunk
  end

  test "fails to upgrade with unsupported http protocol" do
    Kino.Proxy.listen(fn conn ->
      assert_raise ArgumentError, "upgrade to HTTP/2.0 not supported by KinoProxy.Adapter", fn ->
        upgrade_adapter(conn, :"HTTP/2.0", [])
      end
    end)

    conn = conn(:get, "/123/proxy/")
    run_endpoint(conn)
  end

  test "returns the inform" do
    Kino.Proxy.listen(fn conn ->
      conn
      |> inform!(199)
      |> send_resp(200, "it works!")
    end)

    conn = conn(:get, "/123/proxy/")
    assert %{resp_body: "it works!", status: 200} = run_endpoint(conn)
  end

  test "sends a response with a file to be downloaded" do
    file = __ENV__.file
    body = File.read!(file)

    Kino.Proxy.listen(fn conn ->
      send_file(conn, 200, file)
    end)

    conn = conn(:get, "/123/proxy/")
    assert %{resp_body: ^body, status: 200} = run_endpoint(conn)
  end

  defp run_endpoint(conn, opts \\ []) do
    KinoProxy.Endpoint.call(conn, opts)
  end
end
