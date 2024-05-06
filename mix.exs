defmodule KinoProxy.MixProject do
  use Mix.Project

  @version "0.1.0-dev"

  def project do
    [
      app: :kino_proxy,
      version: @version,
      name: "KinoProxy",
      elixir: "~> 1.16",
      preferred_cli_env: [
        "test.all": :test,
        docs: :docs,
        "hex.publish": :docs
      ],
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      docs: docs(),
      deps: deps(),
      aliases: aliases(),
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

  defp deps do
    [
      {:plug, "~> 1.15.3"},
      {:kino, "~> 0.12.3"},
      {:livebook, livebook_opts()}
    ]
  end

  @default_livebook_path Path.expand("../livebook")
  @livebook_path_env "LIVEBOOK_PATH"

  defp livebook_opts do
    cond do
      File.exists?(@default_livebook_path) -> [path: @default_livebook_path, only: :test]
      path = System.get_env(@livebook_path_env) -> [path: path, only: :test]
      :else -> [github: "livebook-dev/livebook", only: :test]
    end
  end

  def aliases do
    ["test.all": ["test --include integration"]]
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
