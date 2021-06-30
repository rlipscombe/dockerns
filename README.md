# DockerNS

## What?

DNS server that uses Docker Engine API as its database.

## Why?

From the host, you want to look up a docker container's IP address.

## Why not dnsmasq in a container?

Because it results in DNS loops for containers that don't exist.

## But I prefer Python!

Fair enough. See https://github.com/phensley/docker-dns instead.

## Compilation

It's written in Elixir, and makes use of the [dns](https://hex.pm/packages/dns) package.

```
mix deps.get
mix escript.build
```

## Running it

### On the host

You can run it on the host:

```
./dockerns --port 11053 --sock /var/run/docker.sock
```

### In a container

Left as an exercise for the reader.

## Network Name

By default, Docker Compose sets up a single default network for your app. If your
project is called "docker", for example, this will be called "docker_default". This is
what we'll assume in the following.

## Testing

This shows that a container can be referred to by the `app_service_N` name, the
`service` name, or by container ID. Port 11053 is as specified above.

```
dig @localhost -p 11053 docker_container_1.docker_default
dig @localhost -p 11053 container.docker_default
dig @localhost -p 11053 d80147f7d1a9.docker_default
```

You MUST specify the suffix, otherwise your local DNS resolver won't know to forward
to `dockerns` (see below for how that's configured).

## Installation

You need to set up your local DNS resolver to forward queries for the relevant
domains to this server.

### Ubuntu 16.04 (systemd, NetworkManager)

Add the following line to `/etc/NetworkManager/dnsmasq.d/docker_default`:

    server=/docker_default/127.0.0.1#11053

Restart the `network-manager` service:

    sudo service network-manager restart

### Ubuntu 18.04 and 20.04 (systemd-resolved, NetworkManager)

1. `sudo apt-get install dnsmasq`. Ignore the error messages, if there are any.
2. Edit `/etc/NetworkManager/NetworkManager.conf` (use `sudo`).
3. In the `[main]` section, add `dns=dnsmasq`.
4. `sudo systemctl restart NetworkManager`.

Then get your resolver to use it:

    # originally a symlink to ../run/systemd/resolve/stub-resolv.conf
    sudo rm /etc/resolv.conf
    # The relative path is correct: it's resolved relative to the symlink
    sudo ln -s ../run/NetworkManager/resolv.conf /etc/resolv.conf

Add the following line to `/etc/NetworkManager/dnsmasq.d/docker_default`:

    server=/docker_default/127.0.0.1#11053

Restart the `NetworkManager` service (yes, again):

    sudo systemctl restart NetworkManager

You might also need to edit `/etc/nsswitch.conf`, as follows.

Change the `hosts:` line from this:

    hosts:          files mdns4_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] dns myhostname

...to this:

    hosts:          files mdns4_minimal [NOTFOUND=return] dns myhostname
