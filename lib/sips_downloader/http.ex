defmodule SipsDownloader.HTTP do
  def get_login_url do
    url = get_login_page() |> SipsDownloader.XMLParser.parse_login_url

    "https://elixirsips.dpdcart.com" <> url
  end

  defp get_login_page do
    login_page_url = "https://elixirsips.dpdcart.com/subscriber/content"
    {:ok, %HTTPoison.Response{body: body, status_code: 200}} = HTTPoison.get(login_page_url)
    body
  end

  def login_session(url, username, password) do
    headers = %{"Content-type" => "application/x-www-form-urlencoded"}
    post_data = {:form, [username: username, password: password]}
    {:ok, response} = HTTPoison.post(url, post_data, headers)
    extract_session_id(response.headers)
  end

  def extract_session_id(headers) do
    cookie = headers |> Enum.find(&cookie_header?/1)
    {_, "symfony=" <> cookie_val} = cookie
    cookie_val |> String.split(";") |> List.first
  end

  def cookie_header?(header) do
    case header do
      {"Set-Cookie", "symfony=" <> _} -> true
      _ -> false
    end
  end

  def download_episodes_feed(username, password) do
    feed_url = "https://elixirsips.dpdcart.com/feed"
    hackney = [basic_auth: {username, password}]
    case HTTPoison.get(feed_url, [], [hackney: hackney]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> body
      {:ok, %HTTPoison.Response{status_code: 401}} -> raise "401 - Unauthorized"
      {:error, response} -> raise "Failed to download feed: #{response.reason}"
    end
  end
end
