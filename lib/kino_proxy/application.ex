defmodule KinoProxy.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [Kino.Proxy]
    opts = [strategy: :one_for_one, name: KinoProxy.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
