defmodule LiveQchatex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    Logger.info("Starting app version: #{inspect(version())}", ansi_color: :yellow)

    # List all child processes to be supervised
    children = [
      {Cluster.Supervisor,
       [env() |> cluster_topologies(), [name: LiveQchatex.ClusterSupervisor]]},
      # Start the application repository
      LiveQchatex.Repo,
      # Start the endpoint when the application starts
      LiveQchatexWeb.Endpoint,
      # Start the presence worker
      LiveQchatex.Presence,
      # Start the cron tasks worker
      LiveQchatex.Cron
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LiveQchatex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    LiveQchatexWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def get_repo_pid() do
    Process.whereis(LiveQchatex.Repo)
  end

  def env, do: Application.get_env(:live_qchatex, LiveQchatexWeb.Endpoint)[:environment]
  def env?(environment), do: env() == environment

  def version, do: Application.get_env(:live_qchatex, LiveQchatexWeb.Endpoint)[:version]
  def version(key), do: version()[key]

  defp cluster_topologies(:test), do: []

  defp cluster_topologies(_),
    do: [
      gossip: [
        strategy: Cluster.Strategy.Gossip,
        config: [secret: "eG0AWVt6t2daMBx89/sDtQV1UsG8IFINeFhZImU23MW56q0Cni9ffiqnetmTCVHC"]
      ]
      # Just an example of EPMD topology
      # epmd: [
      #   strategy: Cluster.Strategy.Epmd,
      #   config: [hosts: [:"s1@127.0.0.1", :"s2@127.0.0.1"]]
      # ]
    ]
end
