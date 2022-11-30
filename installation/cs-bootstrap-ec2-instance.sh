#!/bin/bash -e

if [[ $USER != root ]]; then
  echo "This script requires root privileges"
  exit 1
fi

CS_HOSTNAME=$1

if [[ -z $CS_HOSTNAME ]]; then
  echo "The hostname is required"
  exit 1
fi

CS_DOMAINNAME=k8s-saltos-school.net

CS_DEBIAN_CODE_NAME=$(lsb_release -c -s)
CS_DEBIAN_RELEASE=$(lsb_release -r -s)
CS_DEBIAN_VERSION=$(echo $CS_DEBIAN_RELEASE | sed -E "s/([0-9]+)\.[0-9]+(\.[0-9]+)?/\1/")
CS_LINUX_ARCH=$(dpkg --print-architecture)

echo $CS_HOSTNAME > /etc/hostname
hostname $CS_HOSTNAME

#sudo hostnamectl set-hostname "master-node"
#exec bash

CS_IP=$(hostname -I)

if [[ -z $CS_IP ]]; then
  echo "Unable to detect IP"
  exit 1
fi

sed -i -e "s/preserve_hostname: false/preserve_hostname: true/g" /etc/cloud/cloud.cfg
sed -i -e "s/manage_etc_hosts: true/manage_etc_hosts: false/g" /etc/cloud/cloud.cfg.d/01_debian_cloud.cfg

sed -i -e "s/^127.0.1.1\s.*/$CS_IP $CS_HOSTNAME.$CS_DOMAINNAME $CS_HOSTNAME/g" /etc/hosts

grep -c contrib /etc/apt/sources.list || {
  sed -e "s/http:/https:/g" -i /etc/apt/sources.list
  sed -e "s/main/main contrib non-free/g" -i /etc/apt/sources.list
}

apt-get -y update
apt-get -y upgrade
apt-get -y autoremove

apt-get install -y locales-all
locale-gen UTF-8
update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

apt-get -y install \
  adduser \
  apt-transport-https \
  automake \
  autotools-dev \
  build-essential \
  bzip2 \
  ca-certificates \
  ccze \
  curl \
  dirmngr \
  dnsutils \
  fish \
  g++ \
  git \
  htop \
  iotop \
  ipset \
  jq \
  libc-dev \
  libcurl4-openssl-dev \
  libevent-dev \
  libfontconfig1 \
  libopenipmi-dev \
  libpcre3-dev \
  libpng-dev \
  libsnmp-dev \
  libssh2-1-dev \
  libssl-dev \
  libxml2-dev \
  lsb-base \
  lsb-release \
  lsof \
  make \
  net-tools \
  netcat \
  nmap \
  pkg-config \
  psmisc \
  pwgen \
  python3 \
  python3-dev \
  python3-pip \
  software-properties-common \
  sysstat \
  telnet \
  unzip \
  webp \
  zip \
  zlib1g-dev

python3 -m pip install --upgrade pip
python3 -m pip install redis
python3 -m pip install awscli

cat > /etc/security/limits.d/90-cs-ulimits.conf <<EOF
*		soft	nproc		183500
*		hard	nproc		183500

*		soft	nofile		183500
*		hard	nofile		183500
EOF

cat > /etc/ssh/sshd_config.d/cs-sshd.conf <<EOF
Port 21
Port 22
Port 25
Port 993
Port 8022
TCPKeepAlive yes
ClientAliveInterval 300
ClientAliveCountMax 100
EOF

cat > /etc/ssh/ssh_config.d/cs-ssh.conf <<EOF
Host *
  TCPKeepAlive yes
  ServerAliveInterval 300
  ServerAliveCountMax 100
EOF

systemctl restart sshd

cat > /etc/init.d/cgroupfs-boot <<EOF
#!/bin/sh
#
### BEGIN INIT INFO
# Provides:           cgroupfs-boot
# Required-Start:     \$syslog \$remote_fs
# Required-Stop:      \$syslog \$remote_fs
# Default-Start:      2 3 4 5
# Default-Stop:       0 1 6
# Short-Description:  Set up cgroupfs mounts.
# Description:
#  Control groups are a kernel mechanism for tracking and imposing
#  limits on resource usage on groups of tasks.
### END INIT INFO

if [ ! -d /sys/fs/cgroup/systemd ]; then
  mkdir /sys/fs/cgroup/systemd
  mount -t cgroup -o none,name=systemd cgroup /sys/fs/cgroup/systemd
fi
EOF

chmod +x /etc/init.d/cgroupfs-boot
update-rc.d cgroupfs-boot defaults
systemctl daemon-reload
systemctl enable cgroupfs-boot
systemctl start cgroupfs-boot

stat -fc %T /sys/fs/cgroup/

cat > /etc/motd <<EOF
  ____        _ _              ____       _                 _ 
 / ___|  __ _| | |_ ___  ___  / ___|  ___| |__   ___   ___ | |
 \___ \ / _\` | | __/ _ \/ __| \___ \ / __| '_ \ / _ \ / _ \| |
  ___) | (_| | | || (_) \__ \  ___) | (__| | | | (_) | (_) | |
 |____/ \__,_|_|\__\___/|___/ |____/ \___|_| |_|\___/ \___/|_|
                                                              
Saltos School 2022.11.0 debian-$CS_DEBIAN_CODE_NAME-$CS_DEBIAN_VERSION-linux-$CS_LINUX_ARCH

EOF
