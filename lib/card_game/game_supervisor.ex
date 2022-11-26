defmodule CardGame.GameSupervisor do
  @moduledoc """
  This module manages all the games which are running.
  """

  use DynamicSupervisor

  alias CardGame.Application
  alias CardGame.GameWorker

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_game(players) do
    id = UUID.uuid4()
    child_spec = {GameWorker, [%{id: id, players: players}]}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
    id
  end

  def call_message(id, msg) do
    with res <- get_pid_from_registry(id, Application.get_registry()),
         {:ok, pid} <- get_pid_from_res(res),
         {:ok, _reply} = res <- GenServer.call(pid, msg) do
      res
    else
      {:error, error} ->
        {:error, error}

      [] ->
        {:error, "Game does not exists."}

      _ ->
        {:error, "Unknown error."}
    end
  end

  def get_children(), do: DynamicSupervisor.which_children(__MODULE__)

  def via_tuple(name),
    do: {:via, Registry, {Application.get_registry(), name}}

  defp get_pid_from_registry(name, registry), do: Registry.lookup(registry, name)

  defp get_pid_from_res([]), do: []
  defp get_pid_from_res([{pid, nil}]), do: {:ok, pid}
end
