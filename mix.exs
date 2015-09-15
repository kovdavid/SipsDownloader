defmodule SipsDownloader.Mixfile do
  use Mix.Project

  def project do
    [app: :sips_downloader,
     version: "0.2.0",
     name: "SipsDownloader",
     source_url: "https://github.com/DavsX/SipsDownloader",
     elixir: "~> 1.0",
     description: description,
     package: package,
     deps: deps,
     escript: escript]
  end

  defp description do
    """
    Automatically download new ElixirSips episodes
    """
  end

  defp package do
    [
      contributors: ["Dávid Kovács"],
      files: ["bin", "config", "lib", "mix.exs", "README*", "LICENSE*"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/DavsX/SipsDownloader"}
    ]
  end

  def application do
    [applications: [:httpoison]]
  end

  defp deps do
    [{:httpoison, "~> 0.7"},
     {:sweet_xml, "~> 0.2"},
     {:html_entities, git: "https://github.com/martinsvalin/html_entities"}]
  end

  defp escript do
    [main_module: SipsDownloader]
  end
end
