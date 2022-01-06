#!/bin/sh

if [ ! -f /swapfile ]; then
    # Give some swap space
    fallocate -l 1G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile

    swapon /swapfile
    echo /swapfile swap swap defaults 0 0 >> /etc/fstab

    echo vm.swappiness=10 >> /etc/sysctl.conf
    sysctl vm.swappiness=10
fi

DEBIAN_FRONTEND=noninteractive apt-get install -y augeas-tools

## Rotate logs daily
(echo "set \
/files/etc/logrotate.d/*/rule[file='/var/log/btmp']/schedule daily"; \
echo save) | augtool

(echo "set \
/files/etc/logrotate.d/*/rule[file='/var/log/auth.log']/schedule daily"; \
echo save) | augtool

## Limit journald max size
JOURNALD_CONF=/etc/systemd/journald.conf
if [ -f ${JOURNALD_CONF} ]; then
    echo "SystemMaxUse=100M" >> ${JOURNALD_CONF}
    systemctl restart systemd-journald
fi


# Install docker
curl https://releases.rancher.com/install-docker/20.10.sh | sh

