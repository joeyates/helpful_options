defmodule HelpfulOptions.MixProject do
  use Mix.Project

  @version "0.4.2"

  def project do
    [
      app: :helpful_options,
      version: @version,
      elixir: "~> 1.14",
      description: "A configurable command-line options parser",
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
      source_url: "https://github.com/joeyates/helpful_options",
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"],
      groups_for_modules: [
        Core: [
          HelpfulOptions,
          HelpfulOptions.Switches,
          HelpfulOptions.Subcommands,
          HelpfulOptions.Other,
          HelpfulOptions.Logging
        ],
        Errors: [
          HelpfulOptions.Errors,
          HelpfulOptions.SwitchErrors,
          HelpfulOptions.OtherErrors
        ]
      ]
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
