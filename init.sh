#!/bin/bash -e

ip link set $WAN_INTERFACE up
ip link del $WAN_INTERFACE.832 || true
ip link add $WAN_INTERFACE.832 link $WAN_INTERFACE mtu $MTU type vlan id 832 egress 6:6
ip link set $WAN_INTERFACE.832 up

echo 2 > /proc/sys/net/ipv6/conf/$WAN_INTERFACE.832/accept_ra
echo 1 > /proc/sys/net/ipv6/conf/all/forwarding

# Add PCP 6 (802.1Q prio 6)
nft add "table netdev filter"
nft add "chain netdev filter egress { type filter hook egress device $WAN_INTERFACE.832 priority 0; }"

# IPV4
nft insert "rule netdev filter egress udp dport 67 meta priority set 0:6 ip dscp set cs6"
nft insert "rule netdev filter egress ether type arp meta priority set 0:6"

# IPV6
nft insert "rule netdev filter egress udp dport 547 meta priority set 0:6 ip6 dscp set cs6"
nft insert "rule netdev filter egress icmpv6 type { nd-router-solicit, nd-neighbor-solicit, nd-neighbor-advert } meta priority set 0:6 ip6 dscp set cs6"

# Set DSCP to 0 for all other packets
nft add rule netdev filter egress ip dscp set 0
nft add rule netdev filter egress ip6 dscp set 0

iptables -D FORWARD -i $LAN_INTERFACE -o $LAN_INTERFACE -j ACCEPT || true
iptables -A FORWARD -i $LAN_INTERFACE -o $LAN_INTERFACE -j ACCEPT
iptables -D FORWARD -i $LAN_INTERFACE -o $WAN_INTERFACE.832 -j ACCEPT || true
iptables -A FORWARD -i $LAN_INTERFACE -o $WAN_INTERFACE.832 -j ACCEPT
iptables -D FORWARD -i $WAN_INTERFACE.832 -o $LAN_INTERFACE -m state --state ESTABLISHED,RELATED -j ACCEPT || true
iptables -A FORWARD -i $WAN_INTERFACE.832 -o $LAN_INTERFACE -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -D POSTROUTING -t nat -s $LAN_SUBNET -o $WAN_INTERFACE.832 -j MASQUERADE || true
iptables -A POSTROUTING -t nat -s $LAN_SUBNET -o $WAN_INTERFACE.832 -j MASQUERADE

ip6tables -D FORWARD -i $LAN_INTERFACE -o $LAN_INTERFACE -j ACCEPT || true
ip6tables -A FORWARD -i $LAN_INTERFACE -o $LAN_INTERFACE -j ACCEPT
ip6tables -D FORWARD -i $LAN_INTERFACE -o $WAN_INTERFACE.832 -j ACCEPT || true
ip6tables -A FORWARD -i $LAN_INTERFACE -o $WAN_INTERFACE.832 -j ACCEPT
ip6tables -D FORWARD -i $WAN_INTERFACE.832 -o $LAN_INTERFACE -m state --state ESTABLISHED,RELATED -j ACCEPT || true
ip6tables -A FORWARD -i $WAN_INTERFACE.832 -o $LAN_INTERFACE -m state --state ESTABLISHED,RELATED -j ACCEPT

if ! iptables-save | grep -q DOCKER; then
    iptables -D INPUT -i docker0 -j ACCEPT || true
    iptables -A INPUT -i docker0 -j ACCEPT
    iptables -D FORWARD -i docker0 -j ACCEPT || true
    iptables -A FORWARD -i docker0 -j ACCEPT
    iptables -D FORWARD -o docker0 -m state --state ESTABLISHED,RELATED -j ACCEPT || true
    iptables -A FORWARD -o docker0 -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -D POSTROUTING -t nat -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE || true
    iptables -A POSTROUTING -t nat -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE
fi

echo Done setting up networking

/usr/local/bin/up-fiber.sh
