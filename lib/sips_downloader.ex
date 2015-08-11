defmodule SipsDownloader do
  @moduledoc """
  Downloads new ElixirSips episodes (subscription to ElixirSips required)

  Credentials and other information needs to be specified in config/config.exs (see provided sample)

  Execute:
  iex> SipsDownloader.run()
  """

  @download_directory Application.get_env(:episode_download, :directory)

  def main(_args) do
    run
  end

  def run do
    username     = Application.get_env(:sips, :username)
    password     = Application.get_env(:sips, :password)
    download_dir = Application.get_env(:sips, :download_dir)

    login_url = SipsDownloader.HTTP.get_login_url
    session_id = SipsDownloader.HTTP.login_session(login_url, username, password)

    episodes_to_download =
      SipsDownloader.HTTP.download_episodes_feed(username, password)
      |> SipsDownloader.XMLParser.parse_episodes
      |> Enum.filter(&episode_to_download(download_dir, &1))
      |> Enum.reverse

    if Enum.empty?(episodes_to_download) do
      IO.puts "No new episodes to download"
    else
      IO.puts "Downloading episodes"
      SipsDownloader.EpisodeDownloader.run(episodes_to_download, session_id, download_dir)
    end
  end

  def episode_to_download(dir, {name, _}) do
    (Path.join(dir, name) |> File.exists?) == false
  end
end
