FROM debian:13

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install --no-install-recommends -y supervisor iproute2 iptables gettext-base build-essential git ca-certificates && \
    update-ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/Raraph84/dhclient-orange-patched /tmp/dhclient-orange-patched
WORKDIR /tmp/dhclient-orange-patched
RUN ./configure && make && make install && \
    cp /tmp/dhclient-orange-patched/client/scripts/linux /sbin/dhclient-script && chmod +x /sbin/dhclient-script && \
    mkdir -p /var/lib/dhcp /etc/dhclient-enter-hooks.d /etc/dhclient-exit-hooks.d && \
    rm -rf /tmp/dhclient-orange-patched && \
    apt-get remove -y build-essential git && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY init.sh /usr/local/bin/init.sh
COPY up-fiber.sh /usr/local/bin/up-fiber.sh
COPY dhclient-orange-generator.sh /etc/dhcp/dhclient-orange-generator.sh
COPY dhclient-orange-v4.conf.template /etc/dhcp/dhclient-orange-v4.conf.template
COPY dhclient-orange-v6.conf.template /etc/dhcp/dhclient-orange-v6.conf.template
COPY no-dns-dhcp-enter-hook.sh /etc/dhclient-enter-hooks.d/no-dns
COPY ipv6-dhcp-exit-hook.sh /etc/dhclient-exit-hooks.d/setup-ipv6

RUN chmod +x /usr/local/bin/init.sh \
    /etc/dhcp/dhclient-orange-generator.sh \
    /usr/local/bin/up-fiber.sh \
    /etc/dhclient-enter-hooks.d/no-dns \
    /etc/dhclient-exit-hooks.d/setup-ipv6

ENV LAN_INTERFACE=eth0
ENV WAN_INTERFACE=eth1
ENV LAN_SUBNET=192.168.1.0/24
ENV MTU=1500

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
