defmodule SipsDownloaderTest do
  use ExUnit.Case

  setup do
    feed = File.read!("test/feed")
    {:ok, feed: feed}
  end

  test "processing feed", %{feed: feed} do
    links = SipsDownloader.FeedParser.parse_episodes(feed)
    expected = [{"Link1_title.mp4", "Link1_href"},
                {"Link2_title.mp4", "Link2_href"},
                {"Link3_title.mp4", "Link3_href"},
                {"Link4_title.mp4", "Link4_href"}]

    assert links == expected
  end
end
