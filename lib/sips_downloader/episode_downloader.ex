defmodule SipsDownloader.EpisodeDownloader do
  def run(episodes, session_id, download_dir) do
    {:ok, sup} = Task.Supervisor.start_link()
    work_ref = make_ref()

    state = %{running: 0, max_running: 5, work_ref: work_ref, dir: download_dir,
              supervisor: sup, session_id: session_id, pids: %{}, parent: self()}

    ep = hd(episodes)
    download_episode!(ep, state)
  end

  def download_episode!({name, url} = work, state) do
    case make_async_request(url, state.session_id) do
      {:ok, %HTTPoison.AsyncResponse{id: ref}} ->
        worker_state = Enum.into(state, %{name: name, url: url, resp_ref: ref, fh: nil})
        case process_download(worker_state) do
          :ok -> send(state.parent, {state.work_ref, self(), {:ok, name}})
          {:error, reason} -> send(state.parent, {state.work_ref, self(), {:error, reason}})
        end
      {:error, %HTTPoison.Error{reason: reason}} ->
        send(state.parent, {state.work_ref, self(), {:error, reason}})
    end
  end

  defp make_async_request(url, session_id) do
    HTTPoison.get(url, %{}, hackney: [cookie: [{"symfony", session_id}]], stream_to: self())
  end

  defp process_download(state) do
    receive do
      %HTTPoison.AsyncStatus{code: 200} ->
        {:ok, fh} = Path.join(state.dir, state.name) |> File.open([:write])
        IO.puts "Starting download: #{state.name}"
        process_download(%{state | fh: fh})
      %HTTPoison.AsyncStatus{code: code} ->
        {:error, "Could not download episode. Status code #{code}"}
      %HTTPoison.AsyncHeaders{headers: headers} ->
        content_length = Enum.find(headers, fn {name, _} -> name == "Content-Length" end) |> elem(1)
        IO.puts "#{state.name} => #{content_length}"
        :ok
    end
  end
end


  #def download_episode!({name, link}, sid) do
    #IO.puts "Downloading #{name}"

    #{:ok, response} = HTTPoison.get(link, %{}, hackney: [cookie: [{"symfony", sid}]])
    #content = response.body
    #File.write!(Path.join(@download_directory, name), content)
  #end
