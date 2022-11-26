defmodule CardGame.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias CardGame.QueueSupervisor
  alias CardGame.GameSupervisor

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, [keys: :unique, name: get_registry()]},
      {QueueSupervisor, []},
      {GameSupervisor, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CardGame.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def get_registry(), do: CardGame.Registry
end
