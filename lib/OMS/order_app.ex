defmodule ImtOrder.App do
  use Supervisor

  @port 9090

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_) do
    children = [
      ImtOrder.CacheServer, # Cache Server Loading
      {Plug.Cowboy, scheme: :http, plug: ImtOrder.API, options: [port: @port]} # API Loading
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
