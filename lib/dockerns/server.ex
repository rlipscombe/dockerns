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

  def handle(
        record = %DNS.Record{qdlist: [%DNS.Query{type: :aaaa, domain: domain} | _]},
        _
      ) do
        # We don't do AAAA (IPv6) records; return an empty answer section,
        # per https://tools.ietf.org/html/rfc4074#section-3
        Logger.info("AAAA #{domain}: no results")
        %{record | header: %{record.header | qr: true}, anlist: []}
  end
end
