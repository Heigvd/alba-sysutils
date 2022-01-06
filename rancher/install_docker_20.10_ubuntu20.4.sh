#!/bin/sh

if [ ! -f /swapfile ]; then
    # Give some swap space
    sudo fallocate -l 1G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile

    sudo swapon /swapfile
    sudo sh -c "echo /swapfile swap swap defaults 0 0 >> /etc/fstab"

    sudo sh -c "echo vm.swappiness=10 >> /etc/sysctl.conf"
    sudo sysctl vm.swappiness=10
fi

DEBIAN_FRONTEND=noninteractive sudo apt-get install -y augeas-tools

## Rotate logs daily
(echo "set \
/files/etc/logrotate.d/*/rule[file='/var/log/btmp']/schedule daily"; \
echo save) | sudo augtool

(echo "set \
/files/etc/logrotate.d/*/rule[file='/var/log/auth.log']/schedule daily"; \
echo save) | sudo augtool

## Limit journald max size
JOURNALD_CONF=/etc/systemd/journald.conf
if [ -f ${JOURNALD_CONF} ]; then
    sudo sh -c "echo SystemMaxUse=100M >> ${JOURNALD_CONF}"
    sudo systemctl restart systemd-journald
fi


# Install docker
curl https://releases.rancher.com/install-docker/20.10.sh | sh

echo "{
  \"log-driver\": \"json-file\",
  \"log-opts\": {
    \"max-size\": \"10m\",
    \"max-file\": \"4\"
  }
}" | sudo tee /etc/docker/daemon.json > /dev/null
