defmodule Kino.Proxy do
  # TODO: Add module docs
  @moduledoc false

  # TODO: Add function docs
  @doc false
  @spec run(pid(), Plug.Conn.t()) :: {Plug.Conn.t(), atom()}
  defdelegate run(pid, conn), to: KinoProxy.Server

  # TODO: Add function docs
  @doc false
  @spec listen((Plug.Conn.t() -> Plug.Conn.t())) :: :ok
  defdelegate listen(fun), to: KinoProxy.Client
end
