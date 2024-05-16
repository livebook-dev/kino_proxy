defmodule KinoProxy.MixProject do
  use Mix.Project

  @version "0.1.0-dev"

  def project do
    [
      app: :kino_proxy,
      version: @version,
      name: "KinoProxy",
      elixir: "~> 1.16",
      preferred_cli_env: preferred_cli_env(),
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      docs: docs(),
      deps: deps(),
      package: package()
    ]
  end

  def application do
    [
      mod: {KinoProxy.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp preferred_cli_env do
    [
      docs: :docs,
      "hex.publish": :docs
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.15.3"},
      {:jason, "~> 1.4.1", only: :test}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: "https://github.com/livebook-dev/kino_proxy",
      source_ref: "v#{@version}",
      extras: ["README.md"]
    ]
  end

  def package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/livebook-dev/kino_proxy"
      }
    ]
  end
end
