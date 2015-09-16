defmodule SipsDownloader.ParallelDownloader do
  def run(episodes, session_id, download_dir) do
    {:ok, sup} = Task.Supervisor.start_link()

    state = %{
      dir: download_dir,
      max_running: 5,
      parent: self(),
      pids: %{},
      running: 0,
      session_id: session_id,
      supervisor: sup,
      work_ref: make_ref()
    }

    schedule_downloads(episodes, state)
  end

  defp schedule_downloads([], %{running: 0}), do: IO.puts "Finished downloading!"
  defp schedule_downloads(episode_queue, state) do
    if (state.running < state.max_running) and (length(episode_queue) > 0) do
      {:ok, episode_queue, state} = download_episode(episode_queue, state)
      schedule_downloads(episode_queue, state)
    else
      {:ok, episode_queue, state} = receive_download_msg(episode_queue, state)
      schedule_downloads(episode_queue, state)
    end
  end

  defp receive_download_msg(episode_queue, state) do
    work_ref = state.work_ref
    receive do
      {^work_ref, worker_pid, _work = {name, _url}, {:ok}} ->
        IO.puts "Finished #{name}"
        pids = Map.delete(state.pids, worker_pid)
        state = %{state | pids: pids, running: state.running - 1}
        {:ok, episode_queue, state}

      {^work_ref, worker_pid, _work = {name, _url}, {:redirect, location}} ->
        IO.puts "Redirect for #{name}"
        pids = Map.delete(state.pids, worker_pid)
        state = %{state | pids: pids, running: state.running - 1}
        new_work = {name, location}
        episode_queue = [new_work | episode_queue]
        {:ok, episode_queue, state}

      {^work_ref, worker_pid, _work = {name, _url}, {:error, reason}} ->
        IO.puts "Failed to download #{name}: #{reason}"
        pids = Map.delete(state.pids, worker_pid)
        state = %{state | pids: pids, running: state.running - 1}
        {:ok, episode_queue, state}

      {:DOWN, monitor_ref, _, worker_pid, reason} ->
        if Map.has_key?(state.pids, worker_pid) do
          Process.demonitor(monitor_ref)
          {_work = {name, _url}, pids} = Map.pop(state.pids, worker_pid)
          IO.puts "Failed to download #{name}: #{inspect reason}"
          state = %{state | pids: pids, running: state.running - 1}
          {:ok, episode_queue, state}
        else
          {:ok, episode_queue, state}
        end

      true ->
        {:ok, episode_queue, state}
    end
  end

  defp download_episode([work | queue], state) do
    {:ok, worker_pid} = spawn_worker(work, state)

    pids = Map.put(state.pids, worker_pid, work)
    state = %{state | pids: pids, running: state.running + 1}

    {:ok, queue, state}
  end

  defp spawn_worker(work = {name, _url}, state) do
    IO.puts "Starting download: #{name}"

    worker_state = Map.take(state, [:work_ref, :dir, :session_id, :parent])

    {:ok, worker_pid} = Task.Supervisor.start_child(
      state.supervisor, SipsDownloader.EpisodeDownloader, :run, [work, worker_state]
    )

    Process.monitor(worker_pid)

    {:ok, worker_pid}
  end
end
