defmodule SipsDownloader.EpisodesFeed do
  def download_episodes_feed(username, password) do
    feed_url = "https://elixirsips.dpdcart.com/feed"
    hackney = [basic_auth: {username, password}]

    IO.puts "Downloading episodes_feed"

    case HTTPoison.get(feed_url, [], [hackney: hackney]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
      {:ok, %HTTPoison.Response{status_code: code}} ->
        raise "Failed to download feed. Status code #{code}"
      {:error, response} ->
        raise "Failed to download feed: #{response.reason}"
    end
  end
end
