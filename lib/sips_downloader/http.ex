defmodule SipsDownloader.Http do
  @download_directory Application.get_env(:episode_download, :directory)

  def download_episodes_feed do
    feed_url = Application.get_env(:episode_feed, :feed_url)
    username = Application.get_env(:episode_feed, :username)
    password = Application.get_env(:episode_feed, :password)

    hackney = [basic_auth: {username, password}]
    case HTTPoison.get(feed_url, [], [hackney: hackney]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> body
      {:ok, %HTTPoison.Response{status_code: 401}} -> raise "401 - Unauthorized"
      {:error, response} -> raise "Failed to download feed: #{response.reason}"
    end
  end

  def login_session do
    login_url = Application.get_env(:episode_download, :login_url)
    username  = Application.get_env(:episode_download, :username)
    password  = Application.get_env(:episode_download, :password)

    headers = %{"Content-type" => "application/x-www-form-urlencoded"}
    post_data = {:form, [username: username, password: password]}
    {:ok, response} = HTTPoison.post(login_url, post_data, headers)
    extract_session_id(response.headers)
  end

  def extract_session_id(headers) do
    cookie = headers |> Enum.filter(&cookie_header?/1) |> List.first
    {_, "symfony=" <> cookie_val} = cookie
    cookie_val |> String.split(";") |> List.first
  end

  def cookie_header?(header) do
    case header do
      {"Set-Cookie", "symfony=" <> _} -> true
      _ -> false
    end
  end

  def download_episode!({name, link}, sid) do
    IO.puts "Downloading #{name}"

    {:ok, response} = HTTPoison.get(link, %{}, hackney: [cookie: [{"symfony", sid}]])
    content = response.body
    File.write!(Path.join(@download_directory, name), content)
  end
end
