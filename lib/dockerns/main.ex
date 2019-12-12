defmodule Dockerns.Main do
  require Logger

  @port 11053
  @sock "/var/run/docker.sock"

  def main(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [port: :integer, sock: :string])
    port = opts[:port] || @port
    sock = opts[:sock] || @sock

    children = [{Dockerns.Database, sock}, {Dockerns.Server, port}]
    {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)
    :timer.sleep(:infinity)
  end
end
