defmodule Dockerns.Refresh do
  def refresh(sock) do
    json = get_containers_json(sock)
    containers = Jason.decode!(json)

    Enum.reduce(containers, %{}, fn c, acc ->
      acc = add_names(c, acc)
      acc = add_aliases(sock, c, acc)
      acc
    end)
  end

  defp add_names(c, acc) do
    names = get_in(c, ["Names"]) |> Enum.map(fn n -> String.trim_leading(n, "/") end)
    networks = get_in(c, ["NetworkSettings", "Networks"])

    records =
      for name <- names, {network, settings} <- networks do
        address = get_in(settings, ["IPAddress"])
        {name, network, address}
      end

    Enum.reduce(records, acc, fn {name, network, address}, acc ->
      Map.put(acc, name <> "." <> network, address)
    end)
  end

  defp add_aliases(sock, c, acc) do
    json = get_inspect_json(sock, c)
    inspect = Jason.decode!(json)
    networks = get_in(inspect, ["NetworkSettings", "Networks"]) |> or_default([])

    records =
      for {network, settings} <- networks do
        aliases = get_in(settings, ["Aliases"]) |> or_default([])
        address = get_in(settings, ["IPAddress"]) |> or_default([])

      Enum.reduce(aliases, [], fn a, recs ->
        [{a, network, address} | recs]
      end)
    end

    records = List.flatten(records)

    Enum.reduce(records, acc, fn {name, network, address}, acc ->
      Map.put(acc, name <> "." <> network, address)
    end)
  end

  defp get_containers_json(sock) do
    # curl --unix-socket /var/run/docker.sock -X GET http:/1.40/containers/json
    get_json(sock, "/containers/json")
  end

  defp get_inspect_json(sock, c) do
    # curl --unix-socket /var/run/docker.sock -X GET http:/1.40/containers/:id/json
    id = Map.get(c, "Id")
    get_json(sock, "/containers/#{id}/json")
  end

  defp get_json(sock, path) do
    # https://ninenines.eu/docs/en/gun/1.3/manual/gun.open_unix/
    {:ok, conn} = :gun.open_unix(String.to_charlist(sock), %{})
    {:ok, _} = :gun.await_up(conn)
    # https://docs.docker.com/engine/api/v1.40/
    stream = :gun.get(conn, String.to_charlist(path))
    {:ok, json} = :gun.await_body(conn, stream)
    :gun.shutdown(conn)
    :gun.flush(conn)
    json
  end

  defp or_default(nil, default), do: default
  defp or_default(value, _default), do: value
end
