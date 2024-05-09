defmodule KinoProxy.Adapter do
  @moduledoc false
  @behaviour Plug.Conn.Adapter

  def send_resp(pid, status, headers, body) do
    ref = make_ref()
    send(pid, {:send_resp, self(), ref, [status, headers, body]})

    receive(do: ({^ref, response} -> response))
  end
end
