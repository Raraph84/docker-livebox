# Docker Livebox

- **GitHub**: https://github.com/Raraph84/docker-livebox
- **Docker Hub**: https://hub.docker.com/r/raraph84/livebox

A simple Docker image that transforms your host into an Orange Livebox, allowing you to bypass the Orange Livebox router and use your own hardware with Orange fiber (FTTH) in France.

## Overview

This Docker container handles the authentication process with Orange's network infrastructure by:

- Creating and configuring a VLAN 832 interface on your WAN interface
- Generating the required DHCP options (vendor class, user class, option 90 authentication)
- Obtaining IPv4 and IPv6 addresses via DHCPv4 and DHCPv6
- Setting up NAT and forwarding rules for your LAN

## Requirements

- A Linux host with Docker installed
- Two network interfaces (one for LAN, one for WAN connected to the ONT)
- Your Orange fiber credentials (login `fti/xxxxxxx` and password)
- The container must run in privileged mode with host networking

## Quick Start

```bash
docker run -d \
--name livebox \
--privileged \
--network host \
-e FIBER_LOGIN=fti/xxxxxxx \
-e FIBER_PASSWORD=xxxxxxx \
-e LAN_INTERFACE=eth0 \
-e WAN_INTERFACE=eth1 \
-e LAN_SUBNET=192.168.1.0/24 \
raraph84/livebox
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `FIBER_LOGIN` | N/A | Your Orange fiber login (format: `fti/xxxxxxx`) |
| `FIBER_PASSWORD` | N/A | Your Orange fiber password |
| `LAN_INTERFACE` | `eth0` | The network interface connected to your local network |
| `WAN_INTERFACE` | `eth1` | The network interface connected to the Orange ONT |
| `LAN_SUBNET` | `192.168.1.0/24` | Your local network subnet for NAT masquerading |
| `MTU` | `1500` | MTU for the VLAN interface |

## How It Works

1. **VLAN Setup**: Creates a VLAN 832 interface on the WAN interface (required by Orange)
2. **QoS Configuration**: Sets up nftables rules to add proper CoS/DSCP values for DHCP and control traffic
3. **Authentication**: Generates the required DHCP options including the option 90 authentication string
4. **DHCP**: Obtains IPv4 address and IPv6 prefix delegation from Orange's DHCP servers
5. **NAT/Forwarding**: Configures iptables rules for NAT and packet forwarding between LAN and WAN

## Network Setup

```
[Your Devices] <---> [LAN Interface] <---> [Docker Host] <---> [WAN Interface] <---> [Orange ONT] <---> [Orange Network]
```

Make sure your WAN interface is directly connected to the Orange ONT (SFP or Ethernet output).

## Building from Source

```bash
git clone https://github.com/Raraph84/docker-livebox.git
cd docker-livebox
docker build -t livebox .
```

## Notes

- This container requires `--privileged` mode to manage network interfaces and iptables rules
- Host networking (`--network host`) is required to access and configure the host's network interfaces
- The container emulates a Livebox 5 (Sagem) for authentication purposes
- IPv6 prefix delegation is configured to provide IPv6 connectivity to your LAN

## Acknowledgments

Special thanks to:

- The **[lafibre.info](https://lafibre.info/)** community for their valuable knowledge and support regarding Orange fiber connections
- The **[orange-bypass-debian](https://github.com/akhamar/orange-bypass-debian)** project, which provided significant help and inspiration for this implementation

## License

This project is provided as-is for educational and personal use.
