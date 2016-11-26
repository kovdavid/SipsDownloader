defmodule SipsDownloader.EpisodeDownloader do
  def run(work = {_name, url}, state) do
    result = case make_async_request(url, state.session_id) do
      {:ok, %HTTPoison.AsyncResponse{}} ->
        state = Map.merge(state, %{fh: nil, file_size: nil, downloaded_size: nil})
        process_download(work, state)

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end

    send(state.parent, {state.work_ref, self(), work, result})
  end

  defp make_async_request(url, session_id) do
    HTTPoison.get(url, [], [
      hackney: [cookie: [{"symfony", session_id}]],
      stream_to: self()
    ])
  end

  defp process_download(work = {name, _url}, state = %{fh: nil, dir: dir}) do
    receive do
      %HTTPoison.AsyncStatus{code: 200} ->
        {:ok, fh} = Path.expand(dir) |> Path.join(name) |> Kernel.<>(".tmp") |> File.open([:write, :append])
        process_download(work, %{state | fh: fh})

      %HTTPoison.AsyncStatus{code: 302} ->
        receive_redirect_location()

      %HTTPoison.AsyncStatus{code: code} ->
        {:error, "Could not download episode [#{name}]. Status code #{code}"}

      result ->
        {:error, "Expected %HTTPoison.AsyncStatus, got [#{inspect result}]"}
    after
      5_000 -> {:error, "Expected %HTTPoison.AsyncStatus, got nothing after 5s"}
    end
  end

  defp process_download(work, state = %{file_size: nil, downloaded_size: nil}) do
    receive do
      %HTTPoison.AsyncHeaders{headers: headers} ->
        content_length = Enum.find(headers, fn {type, _} -> type == "Content-Length" end)
          |> elem(1)
          |> String.to_integer

        state = %{state | file_size: content_length, downloaded_size: 0}
        process_download(work, state)

      result ->
        {:error, "Expected %HTTPoison.AsyncHeaders, got [#{inspect result}]"}
    after
      5_000 -> {:error, "Expected %HTTPoison.AsyncHeaders, got nothing after 5s"}
    end
  end

  defp process_download(work = {name, _url}, state) do
    file_size = state.file_size
    downloaded_size = state.downloaded_size
    fh = state.fh

    receive do
      %HTTPoison.AsyncChunk{chunk: chunk} ->
        chunk_len = byte_size(chunk)
        :ok = IO.binwrite(fh, chunk)
        process_download(work, %{state | downloaded_size: downloaded_size + chunk_len})

      %HTTPoison.AsyncEnd{} ->
        file_name = Path.join(state.dir, name)
        temp_file_name = file_name <> ".tmp"

        if file_size == downloaded_size do
          :ok = File.cp(temp_file_name, file_name)
          :ok = File.close(fh)
          :ok = File.rm(temp_file_name)

          {:ok}
        else
          :ok = File.close(fh)
          :ok = File.rm(temp_file_name)

          {:error, "Did not manage to download the whole file! #{downloaded_size}/#{file_size}"}
        end

      result ->
        {:error, "Expected %HTTPoison.AsyncChunk/End, got [#{inspect result}]"}

    after
      5_000 -> {:error, "Expected %HTTPoison.AsyncChunk/End, got nothing after 5s"}
    end
  end

  defp receive_redirect_location() do
    receive do
      %HTTPoison.AsyncHeaders{headers: headers} ->
        {"Location", location} = Enum.find(headers, fn {type, _} -> type == "Location" end)
        {:redirect, location}

      result ->
        {:error, "Expected %HTTPoison.AsyncHeaders, got [#{inspect result}]"}
    after
      5_000 -> {:error, "Expected %HTTPoison.AsyncHeaders, got nothing after 5s"}
    end
  end
end
