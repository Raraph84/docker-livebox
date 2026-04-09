FROM debian:13@sha256:c71b05eac0b20adb4cdcc9f7b052227efd7da381ad10bb92f972e8eae7c6cdc9

RUN apt-get update
RUN apt-get install -y supervisor iproute2 iptables gettext-base

RUN apt-get install -y build-essential git
RUN git clone https://github.com/Raraph84/dhclient-orange-patched /tmp/dhclient-orange-patched
RUN cd /tmp/dhclient-orange-patched && ./configure && make && make install
RUN cp /tmp/dhclient-orange-patched/client/scripts/linux /sbin/dhclient-script && chmod +x /sbin/dhclient-script
RUN mkdir -p /var/lib/dhcp /etc/dhclient-enter-hooks.d /etc/dhclient-exit-hooks.d
RUN rm -rf /tmp/dhclient-orange-patched
RUN apt-get remove -y build-essential git && apt-get autoremove -y && apt-get clean

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY init.sh /usr/local/bin/init.sh
COPY up-fiber.sh /usr/local/bin/up-fiber.sh
COPY dhclient-orange-generator.sh /etc/dhcp/dhclient-orange-generator.sh
COPY dhclient-orange-v4.conf.template /etc/dhcp/dhclient-orange-v4.conf.template
COPY dhclient-orange-v6.conf.template /etc/dhcp/dhclient-orange-v6.conf.template
COPY no-dns-dhcp-enter-hook.sh /etc/dhclient-enter-hooks.d/no-dns
COPY ipv6-dhcp-exit-hook.sh /etc/dhclient-exit-hooks.d/setup-ipv6

RUN chmod +x /usr/local/bin/init.sh
RUN chmod +x /etc/dhcp/dhclient-orange-generator.sh
RUN chmod +x /usr/local/bin/up-fiber.sh
RUN chmod +x /etc/dhclient-enter-hooks.d/no-dns
RUN chmod +x /etc/dhclient-exit-hooks.d/setup-ipv6

ENV LAN_INTERFACE=eth0
ENV WAN_INTERFACE=eth1
ENV LAN_SUBNET=192.168.1.0/24
ENV MTU=1500

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
