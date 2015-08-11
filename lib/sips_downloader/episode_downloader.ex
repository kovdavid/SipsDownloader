defmodule SipsDownloader.EpisodeDownloader do
  def run(work = {_name, url}, state) do
    case make_async_request(url, state.session_id) do
      {:ok, %HTTPoison.AsyncResponse{}} ->
        case process_download(work, state) do
          :ok ->
            send(state.parent, {state.work_ref, self(), {:ok, work}})
          {:error, reason} ->
            send(state.parent, {state.work_ref, self(), {:error, reason, work}})
        end
      {:error, %HTTPoison.Error{reason: reason}} ->
        send(state.parent, {state.work_ref, self(), {:error, reason, work}})
    end
  end

  defp make_async_request(url, session_id) do
    HTTPoison.get(url, %{}, hackney: [cookie: [{"symfony", session_id}]], stream_to: self())
  end

  defp process_download(work = {name, _url}, state, fh \\ nil) do
    receive do
      %HTTPoison.AsyncStatus{code: 200} ->
        {:ok, fh} = Path.join(state.dir, name) |> File.open([:write, :append])
        IO.puts "Starting download: #{name}"
        process_download(work, state, fh)
      %HTTPoison.AsyncStatus{code: code} ->
        File.close(fh)
        Path.join(state.dir, name) |> File.rm
        {:error, "Could not download episode. Status code #{code}"}
      %HTTPoison.AsyncHeaders{headers: headers} ->
        content_length =
          Enum.find(headers, fn {name, _} -> name == "Content-Length" end)
          |> elem(1)

        IO.puts "#{name} => #{content_length}"
        process_download(work, state, fh)
      %HTTPoison.AsyncChunk{chunk: chunk} ->
        chunk_len = String.length(chunk)
        #IO.puts "Received #{chunk_len} bytes for #{name}"
        IO.binwrite(fh, chunk)
        process_download(work, state, fh)
      %HTTPoison.AsyncEnd{} ->
        File.close(fh)
        IO.puts "Finished #{name}"
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
