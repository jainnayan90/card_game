defmodule CardGame.QueueSupervisor do
  @moduledoc """
  This module starts a supervisor proces for queuing game users.
  """

  use Supervisor
  alias CardGame.QueueWorker

  @queues ["1"]

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = get_queue_children(@queues)

    Supervisor.init(children, strategy: :one_for_one)
  end

  def call_message(queue_level, msg) do
    case check_queue_exists(queue_level) do
      {:ok, pid} ->
        GenServer.call(pid, msg)

      {:error, _} = error ->
        error
    end
  end

  defp get_queue_children(queues) do
    Enum.map(
      queues,
      fn queue ->
        {QueueWorker, [%{queue_name: get_queue_name(queue)}]}
      end
    )
  end

  defp check_queue_exists(queue_level) do
    procname = get_queue_name(queue_level)

    case Process.whereis(procname) do
      nil ->
        {:error, :no_queue_exists}

      pid ->
        {:ok, pid}
    end
  end

  defp get_queue_name(queue_level),
    do: String.to_atom("CardGame.QueueWorker" <> "_" <> queue_level)
end
