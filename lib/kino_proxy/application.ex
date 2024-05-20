defmodule KinoProxy.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {PartitionSupervisor, child_spec: KinoProxy.Client, name: KinoProxy.PartitionSupervisor}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: KinoProxy.Supervisor)
  end
end
