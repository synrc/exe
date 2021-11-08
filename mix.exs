defmodule EXE.Mixfile do
  use Mix.Project
  def deps, do: [ {:ex_doc, ">= 0.0.0", only: :dev} ]
  def application, do: [mod: {:sh, []}]
  def project do
    [ app: :exe,
      version: "7.11.0",
      description: "EXE Shell Execution",
      package: package(),
      deps: deps()]
  end
  def package do
    [ files: ~w(man c_src src mix.exs rebar.config LICENSE),
      licenses: ["ISC"],
      links: %{"GitHub" => "https://github.com/synrc/exe"}]
  end
end
