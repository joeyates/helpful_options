defmodule HelpfulOptions.MixProject do
  use Mix.Project

  @version "0.3.3"

  def project do
    [
      app: :helpful_options,
      version: @version,
      elixir: "~> 1.14",
      description: "A configurable command-line otptions parser",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp docs() do
    [
      source_ref: "v#{@version}",
      main: "readme",
      extras: ["README.md"]
    ]
  end

  defp package do
    [
      maintainers: ["Joe Yates"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/joeyates/helpful_options"}
    ]
  end
end
