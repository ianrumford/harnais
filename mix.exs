defmodule Harnais.Mixfile do
  use Mix.Project

  @version "1.0.0"

  def project do
    [
      app: :harnais,
      version: @version,
      elixir: "~> 1.6",
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/ianrumford/harnais",
      homepage_url: "https://github.com/ianrumford/harnais",
      docs: [extras: ["./README.md", "./CHANGELOG.md"]],
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.18.3", only: :dev}
    ]
  end

  defp package do
    [
      maintainers: ["Ian Rumford"],
      files: ["lib", "mix.exs", "README*", "LICENSE*", "CHANGELOG*"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/ianrumford/harnais"}
    ]
  end

  defp description do
    """
    harnais: The base package of the Harnais family
    """
  end
end
