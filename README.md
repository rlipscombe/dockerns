# DockerNS

## What?

DNS server that uses Docker Engine API as its database.

## Why?

From the host, you want to look up a docker container's IP address.

## Why not dnsmasq in a container?

Because it results in DNS loops for containers that don't exist.

## Compilation

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

## Testing

```
dig @localhost -p 11053 docker_container_1.docker_network
dig @localhost -p 11053 container.docker_network
dig @localhost -p 11053 d80147f7d1a9.docker_network
```

## Installation

You need to set up your local DNS resolver to forward queries for the relevant
domains to this server.

### Ubuntu 16.04 (systemd, NetworkManager)

Add the following line to `/etc/NetworkManager/dnsmasq.d/docker_network`:

    server=/docker_network/127.0.0.1#11053

Restart the `network-manager` service:

    sudo service network-manager restart

## Ubuntu 18.04 (systemd-resolved, NetworkManager)

1. `sudo apt-get install dnsmasq`. Ignore the error messages.
2. Edit `/etc/NetworkManager/NetworkManager.conf` (use `sudo`).
3. In the `[main]` section, add `dns=dnsmasq`.
4. `sudo systemctl restart NetworkManager`.

Then get your resolver to use it:

    # originally a symlink to ../run/systemd/resolve/stub-resolv.conf
    sudo rm /etc/resolv.conf
    # The relative path is correct: it's resolved relative to the symlink
    sudo ln -s ../run/NetworkManager/resolv.conf /etc/resolv.conf

Add the following line to `/etc/NetworkManager/dnsmasq.d/docker_network`:

    server=/docker_network/127.0.0.1#11053

Restart the `NetworkManager` service (again):

    sudo systemctl restart NetworkManager
