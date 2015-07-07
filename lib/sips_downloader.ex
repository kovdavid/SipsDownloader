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
    session_id = SipsDownloader.Http.login_session

    episodes_to_download =
      SipsDownloader.Http.download_episodes_feed
      |> SipsDownloader.FeedParser.parse_episodes
      |> Enum.filter(&episode_to_download/1)
      |> Enum.reverse

    if Enum.empty?(episodes_to_download) do
      IO.puts "No new episodes to download"
    else
      IO.puts "Downloading episodes"
      Enum.map(episodes_to_download, &(
        SipsDownloader.Http.download_episode!(&1, session_id)
      ))
      episodes_to_download
    end
  end

  def episode_to_download({name, _}) do
    false == Path.join(@download_directory, name) |> File.exists?
  end
end
