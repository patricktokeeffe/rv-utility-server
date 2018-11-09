#!/usr/bin/env bash
#
# Install RPi-Monitor...
# Patrick O'Keeffe <pokeeffe@wsu.edu>
#
# Run this as a sudo user!

# Ensure we have a known current working directory = repo root
cd "${0%/*}/.."

# Get a unique suffix for file backups (".YYYYMMDD_HHMMSS.bak")
bak_date=$(date +.%Y%m%d_%H%M%S.bak)


# Installation procedure, per instructions
echo "Performing complete install procedure..."
apt install dirmngr
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 2C0D3C0F
wget http://goo.gl/vewCLL -O /etc/apt/sources.list.d/rpimonitor.list
apt-get update
apt install rpimonitor -y


# Initialize package update list
echo "Updating system packages status database..."
/etc/init.d/rpimonitor update


# Configure to monitor network traffic
echo "Enabling network monitoring..."
echo "Backing up /etc/rpimonitor/template/network.conf to .../network.conf$bak_date" ...
if [ ! -f /etc/rpimonitor/template/network.conf.bak ]; then
    # hint if .bak not present, then .conf is library version --> back it up sans datestamp
    cp /etc/rpimonitor/template/network.conf /etc/rpimonitor/template/network.conf.bak
fi
cp /etc/rpimonitor/template/network.conf "/etc/rpimonitor/template/network.conf$bak_date"
# Determine so-called "predictable" interface name given to ethernet hardware
iface_name=$(ip link show | grep " en" | cut -d ":" -f 2 | sed 's/ //g')
echo "Found Ethernet interface: $iface_name"
echo "Installing updated network configuration file /etc/rpimonitor/template/network.conf..."
cp src/etc/rpimonitor/template/network.conf /etc/rpimonitor/template/network.conf
sed -i -e "s/eth0/$iface_name/g" /etc/rpimonitor/template/network.conf


# Enable the "Top3" addon
echo 'Enabling addon "Top3"...'
echo 'Installing daily cron trigger...'
cp /usr/share/rpimonitor/web/addons/top3/top3.cron /etc/cron.d/top3
echo "Backing up /etc/rpimonitor/data.conf to .../data.conf$bak_date"
if [ ! -f /etc/rpimonitor/data.conf.bak ]; then
    # hint if .bak not present, then .conf is library version --> back it up sans datestamp
    cp /etc/rpimonitor/data.conf /etc/rpimonitor/data.conf.bak
fi
cp /etc/rpimonitor/data.conf "/etc/rpimonitor/data.conf$bak_date"
echo 'Updating configuration file /etc/rpimonitor/data.conf...'
sed -i -e 's/#web.addons.5.name=Top3/web.addons.5.name=Top3/g' /etc/rpimonitor/data.conf
sed -i -e 's/#web.addons.5.addons=top3/web.addons.5.addons=top3/g' /etc/rpimonitor/data.conf
echo "Backing up /etc/rpimonitor/template/cpu.conf to .../cpu.conf$bak_date"
if [ ! -f /etc/rpimonitor/template/cpu.conf.bak ]; then
    # hint if .bak not present, then .conf is library version --> back it up sans datestamp
    cp /etc/rpimonitor/template/cpu.conf /etc/rpimonitor/template/cpu.conf.bak
fi
echo 'Updating configuration file /etc/rpimonitor/template/cpu.conf...'
sed -i -e 's/#web.status.1.content.1.line.4/web.status.1.content.1.line.4/g' /etc/rpimonitor/template/cpu.conf


# Add services status badges to home page
echo "Enabling service status badge display..."
echo "Backing up /etc/rpimonitor/template/services.conf to .../services.conf$bak_date"
if [ ! -f /etc/rpimonitor/template/services.conf.bak ]; then
    # hint if .bak not present, then .conf is library version --> back it up sans datestamp
    cp /etc/rpimonitor/template/services.conf /etc/rpimonitor/template/services.conf.bak
fi
cp /etc/rpimonitor/template/services.conf "/etc/rpimonitor/template/services.conf$bak_date"
echo "Installing updated configuration file /etc/rpimonitor/template/services.conf..."
cp src/etc/rpimonitor/template/services.conf /etc/rpimonitor/template/services.conf
echo "Skipping backup of /etc/rpimonitor/data.conf, already backed up to /etc/rpimonitor/data.conf$bak_date!"
echo "Updating configuration file /etc/rpimonitor/data.conf..."
# remove prior insertions, if any are found
sed -i -e 's:^include=/etc/rpimonitor/template/services.conf$::g' /etc/rpimonitor/data.conf
# then insert directive at desired location
sed -i -e 's:uptime.conf:uptime.conf\
include=/etc/rpimonitor/template/services.conf:g' /etc/rpimonitor/data.conf


# Enable system service
echo "Enabling rpimonitor.service..."
systemctl enable rpimonitor.service
echo "(Re)Starting rpimonitor.service..."
systemctl restart rpimonitor.service

echo "Finished installing rpimonitor."

