defmodule SipsDownloader.ParallelDownloader do
  def run(episodes, session_id, download_dir) do
    {:ok, sup} = Task.Supervisor.start_link()
    work_ref = make_ref()

    state = %{running: 0, max_running: 5, work_ref: work_ref, dir: download_dir,
              supervisor: sup, session_id: session_id, pids: %{}, parent: self()}

    download_episodes(episodes, state)
  end

  defp download_episodes([], %{running: 0}), do: IO.puts "Finished downloading!"
  defp download_episodes(episode_queue, state) do
    if (state.running < state.max_running) and (length(episode_queue) > 0) do
      [work | episode_queue] = episode_queue

      {:ok, worker_pid} = spawn_worker(work, state)

      pids = Map.put(state.pids, worker_pid, work)

      download_episodes(episode_queue, %{state | pids: pids, running: state.running + 1})
    else
      work_ref = state.work_ref
      receive do
        {^work_ref, worker_pid, {:ok, _work = {name, _url}}} ->
          IO.puts "Finished #{name}"
          pids = Map.delete(state.pids, worker_pid)
          download_episodes(episode_queue, %{state | pids: pids, running: state.running - 1})

        {^work_ref, worker_pid, {:error, reason, _work = {name, _url}}} ->
          IO.puts "Failed to download #{name}: #{reason}"
          pids = Map.delete(state.pids, worker_pid)
          download_episodes(episode_queue, %{state | pids: pids, running: state.running - 1})

        {:DOWN, monitor_ref, _, worker_pid, _} ->
          if Map.has_key?(state.pids, worker_pid) do
            Process.demonitor(monitor_ref)
            {_work = {name, _url}, pids} = Map.pop(state.pids, worker_pid)
            IO.puts "Failed to download #{name}"
            download_episodes(episode_queue, %{state | pids: pids, running: state.running - 1})
          else
            download_episodes(episode_queue, state)
          end

        true ->
            download_episodes(episode_queue, state)
      end
    end
  end

  defp spawn_worker(work, state) do
      worker_state = Map.take(state, [:work_ref, :dir, :session_id, :parent])

      {:ok, worker_pid} = Task.Supervisor.start_child(
        state.supervisor, SipsDownloader.EpisodeDownloader, :run, [work, worker_state]
      )

      Process.monitor(worker_pid)

      {:ok, worker_pid}
  end
end
