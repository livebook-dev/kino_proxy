defmodule KinoProxy.Adapter do
  # TODO: Add module description
  @moduledoc false
  @behaviour Plug.Conn.Adapter

  def send_resp(pid, status, headers, body) do
    ref = make_ref()
    send(pid, {:send_resp, self(), ref, [status, headers, body]})

    receive do
      {^ref, resp} -> resp
    end
  end
end
