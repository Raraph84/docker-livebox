#!/bin/bash -e

/etc/dhcp/dhclient-orange-generator.sh

sleep 2
dhclient -4 -i $WAN_INTERFACE.832 -cf /etc/dhcp/dhclient-orange-v4.conf -df /var/lib/dhcp/dhclient-orange-v4.duid -lf /var/lib/dhcp/dhclient-orange-v4.lease -v
sleep 2
dhclient -6 -P -D LL -i $WAN_INTERFACE.832 -cf /etc/dhcp/dhclient-orange-v6.conf -df /var/lib/dhcp/dhclient-orange-v6.duid -lf /var/lib/dhcp/dhclient-orange-v6.lease -v -e WAN_INTERFACE=$WAN_INTERFACE -e LAN_INTERFACE=$LAN_INTERFACE
