defmodule KinoProxy.Adapter do
  @moduledoc false
  @behaviour Plug.Conn.Adapter

  def send_resp({pid, ref}, status, headers, body) do
    send(pid, {:send_resp, self(), ref, status, headers, body})

    receive do
      {^ref, :ok} -> {:ok, body, {pid, ref}}
      {:DOWN, ^ref, _, _, reason} -> exit({{__MODULE__, :send_resp, 4}, reason})
    end
  end
end
