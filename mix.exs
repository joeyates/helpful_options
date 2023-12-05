defmodule HelpfulOptions.MixProject do
  use Mix.Project

  def project do
    [
      app: :helpful_options,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: []
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end
end
