defmodule Dockerns.Server do
  @behaviour DNS.Server
  use DNS.Server

  require Logger

  def handle(
        record = %DNS.Record{qdlist: [query = %DNS.Query{type: :a, domain: domain} | _]},
        _
      ) do
    case Dockerns.Database.get_a(to_string(domain)) do
      nil ->
        Logger.info("A #{domain}: NXDOMAIN")
        %{record | header: %{record.header | qr: true, rcode: 3}}

      addr ->
        Logger.info("A #{domain}: #{addr}")

        {:ok, ip} = :inet.parse_address(to_charlist(addr))

        rr = %DNS.Resource{
          domain: query.domain,
          class: query.class,
          type: query.type,
          ttl: 0,
          data: ip
        }

        %{record | header: %{record.header | qr: true}, anlist: [rr]}
    end
  end
end
