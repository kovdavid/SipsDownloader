defmodule SipsDownloader do
  @download_directory Application.get_env(:episode_download, :directory)

  def run do
    session_id = SipsDownloader.Http.login_session

    SipsDownloader.Http.download_episodes_feed
    |> SipsDownloader.FeedParser.parse_episodes
    |> Enum.filter(&episode_to_download/1)
    |> Enum.reverse
    |> Enum.map(&(SipsDownloader.Http.download_episode!(&1, session_id)))
  end

  def episode_to_download({name, _}) do
    false == Path.join(@download_directory, name) |> File.exists?
  end
end
