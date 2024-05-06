defmodule Kino.ProxyTest do
  use ExUnit.Case, async: true

  import KinoProxy.TestHelpers

  alias Livebook.{Notebook, Runtime, Session}

  @dependency_path Path.expand("../../", __DIR__)

  setup do
    {:ok, req: Req.new(base_url: LivebookWeb.Endpoint.url(), retry: false)}
  end

  test "it works", %{req: req} do
    setup_cell = %{
      Notebook.Cell.new(:code)
      | source: ~s/Mix.install([{:kino_proxy, path: "#{@dependency_path}"}])/
    }

    notebook = Notebook.put_setup_cell(%{Notebook.new() | name: "My Notebook"}, setup_cell)

    {:ok, session} = Livebook.Sessions.create_session(notebook: notebook)
    {:ok, runtime} = Runtime.ElixirStandalone.new() |> Runtime.connect()

    Session.set_runtime(session.pid, runtime)
    Session.subscribe(session.id)
    evaluate_setup(session.pid)

    cell_id =
      insert_text_cell(
        session.pid,
        insert_section(session.pid),
        :code,
        """
        Kino.Proxy.listen(fn conn ->
          # For test assertive purposes
          ["foo-bar"] = Plug.Conn.get_req_header(conn, "x-auth-token")
          "/foo/bar" = conn.request_path

          conn
          |> Plug.Conn.put_resp_header("content-type", "text/plain")
          |> Plug.Conn.send_resp(200, "it works!")
        end)
        """
      )

    Session.queue_cell_evaluation(session.pid, cell_id)
    assert_receive {:operation, {:add_cell_evaluation_response, _, ^cell_id, _, _}}

    assert "it works!" ==
             Req.get!(req,
               url: "/sessions/#{session.id}/proxy/foo/bar",
               headers: [{"x-auth-token", "foo-bar"}]
             ).body

    Session.close(session.pid)
  end
end
