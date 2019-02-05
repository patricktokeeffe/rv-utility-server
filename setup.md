# Setup Details

## Hardware

The host is a Raspberry Pi 3 with class 10 SD card installed in a plastic case
for basic protection. It's powered through an on/off switch with a 2.5A/5V
power supply on a battery-backed UPS outlet.

* direct ethernet connection to the wifi router (not through a switch that could 
  potentially lose power)
* uninterruptible power supply (UPS) must be connected via USB


----

## Operating System Setup

The operating system choice is [Ubuntu Mate](https://ubuntu-mate.org) because
the Mate desktop is intuitive for our user base. 

> Use 16.04.2 release for Raspberry Pi 3 because (as of Oct 2018) the 18.04
> is not entirely stable.


### Installation Wizard

On first boot, complete the installation wizard questions. The user you create
here will be the administrator account for the machine. 

When prompted for login type, choose to *automatically login without entering
a password*.

### System Upgrades

On (next) first boot, apply system updates then reboot:
```
sudo apt update
sudo apt dist-upgrade -y
...
sudo reboot
```

### Enable SSH Server

Enable the SSH service:
```
sudo systemctl enable ssh.service
sudo systemctl start ssh.service
```

Then add some keys to `~/.ssh/authorized_keys`:
```
# from some other machine:
ssh-copy-id user@our-new-server
```

Test it, of course:
```
ssh user@our-new-server
```

And finally disable password login:
```
sudo nano /etc/ssh/sshd_config
```
```diff
 # Change to no to disable tunnelled clear text passwords
-#PasswordAuthentication yes
+PasswordAuthentication no
```
```
sudo systemctl restart ssh.service
```

### Enable persistent system logs

Ensure *systemd* keeps logs after reboots by creating log directory:
```
sudo mkdir -p /var/log/journal
```

### Fix the *firefox* package

The *Firefox* browser is affected by a crash loop on Ubuntu Mate 16.04 LTS.
Remove it and install *Chromium* instead:
```
sudo apt autoremove firefox -y
sudo apt install chromium-browser -y
```

### Fix the *ureadahead* package

The *ureadahead* package is not functional, but is still included in Ubuntu 
16.04 LTS. Remove it:

> *This package should be removed by Ubuntu 18.10 and this step will be 
> unnecessary [[ref1](https://launchpad.net/ubuntu/+source/ubuntu-meta),
> [ref2](https://askubuntu.com/a/1087007/227779)]*

```
sudo apt autoremove ureadahead
```

### Fix the *cups-filters* package

Ubuntu 16.04 includes kernel drivers for parallel printer ports (which the Pi
does not have). These extra modules prevent the *systemd-modules-load.service*
from loading so remove them and reboot:
```
sudo rm /etc/modules-load.d/cups-filters.conf
sudo reboot
```

Also, prevent package updates from re-introducing this error:
```
sudo bash -c "echo '# do not load parallel port modules
LOAD_LP_MODULES=no' > /etc/default/cups"
```

### Fix the *popularity-contest* package

The *popularity-contest* package is not distributed with a configuration file
in Ubuntu 16.04 LTS. To fix, re-run the package configuration:

> Failing to fix this package will result in constant error messages from
> *cron*, which may result in a slew of unwanted email alerts later on.

```
sudo dpkg-reconfigure popularity-contest
```
### Remove unnecessary packages

These packages won't be useful to support the Research Van, and we don't want
to consume bandwidth with potential updates for nothing. Just uninstall them:

> *To facilitate copy-and-pasting, the following line does **not** include a
> `-y` argument.*

```
sudo apt autoremove --purge scratch minecraft-pi thunderbird youtube-dl youtube-dlg sonic-pi brasero rhythmbox qjackctl sense-emu-tools pidgin hexchat shotwell cheese synapse plank ubuntu-mate-welcome
```

### Disable automatic desktop login

To preserve system resources, boot into command line mode:
> To start the desktop from the command line, run `startx`.
```
sudo raspi-config
```
```
Boot Options -> Desktop / CLI -> Console Text
Boot Options -> Splash Screen -> No
```

Before exiting, also run the *raspi-config* internal update tool.

### Disable built-in Bluetooth and WiFi

This project does not require built-in Bluetooth or WiFi and we can lower
resource consumption by disabling them:
```
sudo nano /boot/config.txt
```
```diff
 ...
+# Disable built-in Bluetooth and WiFi
+dtoverlay=pi3-disable-bt
+dtoverlay=pi3-disable-wifi
```

Also disable associated services to prevent false errors:
```
sudo systemctl stop hcuiart.service
sudo systemctl disable hcuiart.service
sudo systemctl stop wpa_supplicant.service
sudo systemctl disable wpa_supplicant.service
sudo systemctl stop ModemManager.service
sudo systemctl disable ModemManager.service
```

### Install necessary packages

The packages listed below will be necessary, either to setup or operations:
```
sudo apt install -y git
```

---

## Server Hardening

Configure the server for reliable and secure operation per this section.

### Enable watchdog hardware

Prevent catastrophic system hangs by enabling a hardware watchdog module.

> As of Nov 2018, there are two good approaches
> ([read more](https://www.raspberrypi.org/forums/viewtopic.php?p=1373613)): 
> the *watchdog* package, and the *systemd* service named *watchdog*. Since
> the *systemd* service is apparently not included in Ubuntu Mate 16.04 LTS,
> we to use the *watchdog* package.
> ([More reading](https://www.raspberrypi.org/forums/viewtopic.php?f=29&t=147501))

First enable hardware support:
```
sudo nano /boot/config.txt
```
```diff
 ## watchdog
 ##     Set to "on" to enable the hardware watchdog
 ##
 ##     Default off.
 ##
-#dtparam=watchdog=off
+dtparam=watchdog=on
```
```
sudo reboot
```

Then install *watchdog* and fix its broken *systemd* service file:
```
sudo apt install watchdog -y
sudo bash -c "cp /lib/systemd/system/watchdog.service /etc/systemd/system/
> echo 'WantedBy=multi-user.target' >> /etc/systemd/system/watchdog.service"
```

Next, configure the *watchdog* daemon to prevent system freezes:
```
sudo nano /etc/watchdog.conf
```
```diff
 #ping                   = 172.31.14.1
 #ping                   = 172.26.1.255
 #interface              = eth0
 #file                   = /var/log/messages
 #change                 = 1407
 
 # Uncomment to enable test. Setting one of these values to '0' disables it.
 # These values will hopefully never reboot your machine during normal use
 # (if your machine is really hung, the loadavg will go much higher than 25)
-#max-load-1             = 24
+max-load-1             = 24
 #max-load-5             = 18
 #max-load-15            = 12
 
 # Note that this is the number of pages!
 # To get the real size, check how large the pagesize is on your machine.
 #min-memory             = 1
 #allocatable-memory     = 1
 
 #repair-binary          = /usr/sbin/repair
 #repair-timeout         =
 #test-binary            =
 #test-timeout           =
 
-#watchdog-device        = /dev/watchdog
+watchdog-device        = /dev/watchdog
+
+watchdog-timeout = 10
 
 # Defaults compiled into the binary
 #temperature-device     =
 #max-temperature        = 120
 
 # Defaults compiled into the binary
 #admin                  = root
-#interval               = 1
+interval               = 1
 #logtick                = 1
 #log-dir                = /var/log/watchdog
 
 # This greatly decreases the chance that watchdog won't be scheduled before
 # your machine is really loaded
 realtime                = yes
 priority                = 1
 
 # Check if rsyslogd is still running by enabling the following line
 #pidfile                = /var/run/rsyslogd.pid
```

And finally, enable and test the service (with a fork bomb):
```
sudo systemctl enable watchdog
sudo systemctl start watchdog
:(){ :|:& };:
```

..or a NULL pointer dereference:
```
echo c > /proc/sysrq-trigger
```







## Server Software Configuration

Packages are listed in a roughly-recommended order of installation:


### Terminal Session Manager (*tmux*)

Install *tmux*:
```
sudo apt install tmux
```

Modify profile to automatically start *tmux* when logged in over SSH 
[[ref](https://stackoverflow.com/a/40192494/2946116)]:
> *Run this command as your admin user, not root (do not use sudo).*
```
echo '
if [[ -z "$TMUX" ]] && [ "$SSH_CONNECTION" != "" ]; then
    tmux attach-session -t ssh_tmux || tmux new-session -s ssh_tmux
fi
' >> .bashrc
```

> *Future work?* <https://github.com/tmux-plugins/tmux-continuum>


### System Monitoring Service (*RPi-Monitor*)

Install *RPi-Monitor* using the script in this repository:
```
sudo scripts/install_rpimonitor.sh
```

The script above performs the following changes w.r.t. a default installation:
* enables the networking module
    * automatically identifies correct network interface name and updates conf files
    * adds networking to status & statistics pages
* enables the services module
    * disables not-presently-installed services such as *nginx* and *mysql*
    * adds to-be-installed services such as *vnc* and *postfix*
* enables the "Top3" add-on, for identifying cpu-intensive processes

> The install script is careful to backup files before making any modifications.
> There are two sets of backups are made:
> * upon very first run, default installation files are backed up with a `.bak` suffix
> * upon every single run including the very first, files are backed up with a
>   date-stamped suffix (e.g. `.YYYYMMDD_HHMMSS.bak`)

&nbsp;

> **Performance testing notes**
>
> The following items have been held back so that RPi-Monitor can collect
> baseline performance data:
>
> * graphical vs. command line desktop boot
> * for the VPN (ocserv), the use of DTLS vs. TCP BBR


### Automatic Package Updates (*unattended-upgrades*)

Install *unattended-upgrades*:
```
sudo apt install unattended-upgrades
```

This repo contains a copy of `/etc/apt/apt.conf.d/50unattended-upgrades` modified to:
* automatically install security updates
    * removes unused dependencies automatically (`apt-get autoremove`)
    * reboot automatically, if required, at 2AM
* email reports to user *root*

Replace the default configuration file with the repository copy:

> *The conf file provided in this repo has a different prefix number (49) so
> the following commands are safe to execute more than once.*

```
sudo mv /etc/apt/apt.conf.d/50unattended-upgrades /etc/apt/apt.conf.d/50unattended-upgrades.disabled
sudo cp src/etc/apt/apt.conf.d/49unattended-upgrades /etc/apt/apt.conf.d/
```

> As of Ubuntu MATE 16.04.5 LTS, the file `/etc/apt/apt.conf.d/20auto-upgrades`
> is already correctly configured and does not need modification:
> ```
> APT::Periodic::Update-Package-Lists "1";
> APT::Periodic::Unattended-Upgrade "1";
> ```

Then test it:
```
sudo unattended-upgrade --debug --dry-run
```

#### Disable OS Update Advertisements

By default, Ubuntu announces new OS releases and they will appear as daily
emails. To disable this, delete the relevant cron file:
```
sudo rm /etc/cron.weekly/update-notifier-common
```


### Email relay (*postfix*)

Install *postfix* and follow prompts from package installer:
```
sudo apt install postfix -y
```
* Configure as *Satellite* site
* Use hostname for "system mail name"
* Specify complete email relay server address (we're using *smtp.gmail.com:587*)

Configure *postfix* for SASL authentication:
```
sudo postconf -e 'smtp_use_tls = yes'
sudo postconf -e 'smtp_sasl_auth_enable = yes'
sudo postconf -e 'smtp_sasl_password_maps = hash:/etc/postfix/sasl/sasl_password'
sudo postconf -e 'smtp_sasl_security_options = noanonymous'
sudo postconf -e 'smtp_sasl_tls_security_options = noanonymous'
```

Create a new credentials file:
> *Google/Gmail users: for security sake, use an 
> [app password](https://support.google.com/accounts/answer/185833?hl=en)
> instead of your account password!*
```
sudo nano /etc/postfix/sasl/sasl_password
```
```
smtp.gmail.com yourusername@gmail.com:password
```

...and apply appropriate file permissions:
> *Hint: in this order or you'll receive permission errors due to the asterisk*
```
sudo postmap /etc/postfix/sasl/sasl_password
sudo chmod 640 /etc/postfix/sasl/*
sudo chmod 750 /etc/postfix/sasl
sudo chown -R root:postfix /etc/postfix/sasl
```

Now... (since we're using Gmail) disable IPv6 protocol to prevent mail
delivery failures [[ref](https://serverfault.com/a/916168/276001)]:
```
sudo postconf -e inet_protocols=ipv4
```

Restart the service and test (*mail* is in *mailutils*):
```
sudo systemctl restart postfix
```
```
sudo apt install mailutils -y
echo "postfix test" | mail -s "test message" myemail@example.com
```

Next, configure local mail forwarding using `/etc/aliases`
[[ref](https://unix.stackexchange.com/a/21582/160424)]:
* forward user *root*'s mail to your user account
* forward your user account's mail to an external email address
```
sudo bash -c "echo '\
root:   newuser
newuser: myemail@example.com' >> /etc/aliases"
sudo newaliases
```

Test forwarding:
```
echo "postfix forward test" | mail -s "test message" myemail@example.com
```

Finally, configure *postfix* as an open relay on the local area network:
> *Don't do this if your computer is on an unsecure local area network (such as
> at a University).*
1. add the LAN route (ex: 192.168.1.0/24) to the source network list
2. change listening interface from localhost to all network adapters

> **TODO** *investigate more specific `inet_interfaces` setting... attempting
> to use `sudo postconf -e 'inet_interfaces = 127.0.0.1, [::1], 192.168.3.2'`
> produces errors related to the `[::1]` address. Need to remove because IPv4
> is disabled?*

```
sudo postconf -e 'mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 192.168.3.0/24'
sudo postconf -e 'inet_interfaces = all'
sudo postfix reload
```

To test the relay:
* use a different computer on the same LAN subnet to send an email message
    * on Windows, you can use the command line program [sendEmail](http://caspian.dotconf.net/menu/Software/SendEmail/)
    * on Linux, you can use the same *mail* program from the *mailutils* package
* specify the ip address of the *postfix* server computer as the smtp server
    * do not provide any authentication to the *postfix* server
    * ensure there are no firewalls in the way
    * ensure you're on the LAN network specified above (192.168.3.0/24 in our examples)

References:
* https://help.ubuntu.com/lts/serverguide/postfix.html
* http://www.postfix.org/postfix.1.html
* http://www.postfix.org/postconf.5.html


### Network Time Protocol (*chrony*)

> In Ubuntu 16.04, the traditional Network Time Protocol (NTP) package *ntpd*
> is replaced with the *systemd* service *prefer-timesyncd*. This package is a
> client-only implementation and is intended to be replaced with *chrony* to
> obtain an NTP server. *chrony* is newer and has some advantages over *ntpd*.

The complete write-up for implentation of the NTP time server component
is beyond the scope of this document. Instead, refer to the instructions
[described here](https://github.com/patricktokeeffe/rpi-ntp-server) to:
* integrate GPS receiver hardware
* configure the *chrony* and *gpsd* services
* expose the time service to network clients
* and (**FUTURE**) add a physical clock display

After enabling the device as an NTP-GPS server, manually install the
[`chrony.conf` file](https://github.com/XavierBerger/RPi-Monitor/raw/develop/src/etc/rpimonitor/template/chrony.conf):
```
wget https://github.com/XavierBerger/RPi-Monitor/raw/develop/src/etc/rpimonitor/template/chrony.conf
sudo cp ./chrony.conf /etc/rpimonitor/template/
```

Then enable statistics monitoring within RPi-Monitor:
```
sudo nano /etc/rpimonitor/data.conf
```
```diff
 ...
 include=/etc/rpimonitor/template/version.conf
 include=/etc/rpimonitor/template/uptime.conf
 include=/etc/rpimonitor/template/services.conf
+include=/etc/rpimonitor/template/chrony.conf
 include=/etc/rpimonitor/template/cpu.conf
 include=/etc/rpimonitor/template/temperature.conf
 ...
```
```
sudo systemctl restart rpimonitor.service
```


### VPN Server (*ocserv*)

First, create a normal (non-admin) user to act as the VPN account:
```
sudo adduser vpn
```

Install *ocserv*:
```
sudo apt install ocserv -y
```

#### Generate SSL certificate

A self-signed one is perfectly fine, it just results in security
warnings (as it should). ([Reference](https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-apache-in-ubuntu-16-04)):
```
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/ocserv-selfsigned.key -out /etc/ssl/certs/ocserv-selfsigned.pem
```

Of course, a professional installation requires a domain name
and "real" SSL certificate. Getting a domain name is beyond this
document, but getting a free SSL certificate from [Let's Encrypt](https://letsencrypt.org/)
is done as follows.

First, add the [Certbot](https://certbot.eff.org/) repository:
```
sudo apt-get update
sudo apt-get install software-properties-common
sudo add-apt-repository universe
sudo add-apt-repository ppa:certbot/certbot
```
Press <kbd>enter</kbd> to confirm, then install *certbot*:
```
sudo apt-get update && sudo apt-get install certbot -y
```

Next, request a certificate using the standalone plugin.
Before proceeding, ensure any firewalls have port 80 open
and port forwarding rules exist, if needed. To avoid stopping
the VPN service, an http challenge is requested.
```
sudo certbot certonly --standalone -d vpn.example.com --preferred-challenges http --agree-tos --email your@address.com
```

> In the futuure, if RPi-Monitor or another web server is
> exposed on :80 or :443, these directions will probably
> need to adapt to using *haproxy* or similar.

Test automatic renewal. By default, *certbot* installs a 
crontab entry that renews certificates before expiration.
```
sudo certbot renew --dry-run
```

#### Edit the configuration file 

As follows. ([Reference](https://www.linuxbabe.com/ubuntu/openconnect-vpn-server-ocserv-ubuntu-16-04-17-10-lets-encrypt)):
```
sudo nano /etc/ocserv/ocserv.conf
```

Specify the location of the new SSL certificate:
```diff
-server-cert = /etc/ssl/certs/ssl-cert-snakeoil.pem
-server-key = /etc/ssl/private/ssl-cert-snakeoil.key
+server-cert = /etc/letsencrypt/live/servername/fullchain.pem
+server-key = /etc/letsencrypt/live/servername/privkey.pem
```

Disable namespaces worker isolation because it is not enabled in
the kernel we are using. (For more information, see [this issue](https://github.com/raspberrypi/linux/issues/1172).)
```diff
-isolate-workers = true
+isolate-workers = false
```

Increase the number of identical clients, since all users will
share a single account login:
```diff
-max-same-clients = 2
+max-same-clients = 16
```

Enable MTU discovery to optimize VPN performance:
```diff
-try-mtu-discovery = false
+try-mtu-discovery = true
```

Update the value for `default-domain`. Since we do not have a domain
name, we simply provided the public IP address.
```diff
-default-domain = example.com
+default-domain = your.domain.com
```

Disable predictable IP addresses since multiple users will be using
the same account login:
```diff
-predictable-ips = true
+predictable-ips = false
```

Update the `default-domain` value as appropriate:
```diff
-#default-domain=example.com
+default-domain=yourserverdomain.com
```

The van uses the network range 192.168.**3**.0/24 to avoid clashing 
with popular home network ranges (i.e. 192.168.1.x). The router is 
192.168.3.1 and it assigns DHCP addresses in the .100-249 range. 
Static leases are assigned in the .2-30 range but that range may
increase in size so a good range for VPN clients would be .64-96 
(=192.168.3.64/27). 
```diff
-ipv4-network = 192.168.1.0
-ipv4-netmask = 255.255.255.0
+
+# 32 hosts: 192.168.3.64 - .95
+ipv4-network = 192.168.3.64/27
```

> Leave the `tunnel-all-dns` parameter unedited to prevent VPN users
> from sending unecessary traffic over the VPN connection.

Specify the router as the DNS server:
```diff
-dns = 192.168.1.2
+dns = 192.168.3.1
```

Enable `ping-leases` as additional safety precaution against
address collision (e.g. sloppy static IP assignment or changes
to router DHCP range):
```diff
-ping-leases = false
+ping-leases = true
```

Add the specific routes to the van network and the modem, instead
of acting as the default gateway. This configuration limits 
unnecessary traffic (=data usage & power) from VPN clients.
```diff
-route = 10.10.10.0/255.255.255.0
-route = 192.168.0.0/255.255.0.0
-#route = fef4:db8:1000:1001::/64
-#route = default
+route = 192.168.3.0/24
+route = 192.168.13.31/32

 # Subsets of the routes above that will not be routed by
 # the server.

-no-route = 192.168.5.0/255.255.255.0
+#no-route = 192.168.5.0/255.255.255.0
```

For compatibility with the proprietary Cisco AnyConnect client,
enable a profile file for clients (to be created later):
> The path specified here must be the path of the file created later.
```diff
 #user-profile = /path/to/file.xml
+user-profile = /home/user/profile.xml
```

Save changes to `/etc/ocserv/ocserv.conf` and restart *ocserv*:
```
sudo systemctl restart ocserv.service
```

#### Create AnyConnect profile file

For compatibility with Cisco clients, create a profile file in
a location accessible by the vpn user. ([Hat tip](https://gist.github.com/luginbash/52e745ab46cdf46b9061))
For example, with a vpn account named "user":
> Use `-u user` with `sudo` to ensure the user account
> has ownership of the created file. 
> 
> Be sure to update this example with server-specific details.
```
sudo -u user nano /home/user/profile.xml
```
```
<?xml version="1.0" encoding="UTF-8"?>
<AnyConnectProfile xmlns="http://schemas.xmlsoap.org/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://schemas.xmlsoap.org/encoding/ AnyConnectProfile.xsd">

    <ClientInitialization>
        <AutoUpdate UserControllable="true">true</AutoUpdate>
        <UseStartBeforeLogon UserControllable="false">false</UseStartBeforeLogon>
        <StrictCertificateTrust>false</StrictCertificateTrust>
        <RestrictPreferenceCaching>false</RestrictPreferenceCaching>
        <RestrictTunnelProtocols>IPSec</RestrictTunnelProtocols>
        <BypassDownloader>true</BypassDownloader>
        <WindowsVPNEstablishment>AllowRemoteUsers</WindowsVPNEstablishment>
        <CertEnrollmentPin>pinAllowed</CertEnrollmentPin>
        <CertificateMatch>
            <KeyUsage>
                <MatchKey>Digital_Signature</MatchKey>
            </KeyUsage>
            <ExtendedKeyUsage>
                <ExtendedMatchKey>ClientAuth</ExtendedMatchKey>
            </ExtendedKeyUsage>
        </CertificateMatch>
    </ClientInitialization>

    <ServerList>
        <HostEntry>
                <HostName>Alias for host, IP address or FQDN in GUI list</HostName>
                <HostAddress>IP address or FQDN of the server</HostAddress>
        </HostEntry>
    </ServerList>
</AnyConnectProfile>
```

#### Fix DTLS Handshake Failure

Next, disable the "ocserv.socket" service to prevent DTLS failures
([ref](https://www.linuxbabe.com/ubuntu/openconnect-vpn-server-ocserv-ubuntu-16-04-17-10-lets-encrypt)):

```
sudo cp lib/systemd/system/ocserv.service /etc/systemd/system/
sudo nano /etc/systemd/system/ocserv.service
```
```diff
 [Unit]
 Description=OpenConnect SSL VPN server
 Documentation=man:ocserv(8)
 After=network-online.target
-Requires=ocserv.socket
 
 [Service]
 PrivateTmp=true
 PIDFile=/var/run/ocserv.pid
 ExecStart=/usr/sbin/ocserv --foreground --pid-file /var/run/ocserv.pid --config /etc/ocserv/ocserv.conf
 ExecReload=/bin/kill -HUP $MAINPID
 Restart=always
 RestartSec=1
 
 [Install]
 WantedBy=multi-user.target
-Also=ocserv.socket
```
```
sudo systemctl daemon-reload
sudo systemctl stop ocserv.socket
sudo systemctl mask ocserv.socket
sudo systemctl restart ocserv.service
```

Here we used `mask` instead of `disable` to ensure that
*ocserv.socket* cannot be started *even if listed as a
dependency by another service*. (Though, admittedly, I did
this to obtain tab completion on `sudo systemctl restart oc<TAB>`.)

> If you still observe "DTLS handshake failed" errors on
> VPN clients after this procedure, one likely explanation
> is that UDP traffic is still enabled in
> `/etc/ocserv/ocserv.conf`, but it is being blocked by
> a firewall or missing port forward rule.

#### Configure packet routing

Instead of modifying `/etc/sysctl.conf` for this section,
put configuration changes in a new file:
```
sudo nano /etc/sysctl.d/30-ocserv-rules.conf
```

First, permit the VPN server to route packets between clients
and the Internet by enabling **IP Forwarding**:
```diff
+net.ipv4.ip_forward=1
```

Next, allow VPN and LAN to overlap IP address ranges by enabling
**Proxy ARP** ([reference](http://ocserv.gitlab.io/www/recipes-ocserv-pseudo-bridge.html)).
```diff
 net.ipv4.ip_forward=1
+net.ipv4.conf.all.proxy_arp=1
```

Save changes and make effective:
```
sudo sysctl -p /etc/sysctl.d/30-ocserv-rules.conf
```

#### Configure firewall routing

Finally, link the VPN to the network and Internet by enabling IP masquerading.
First determine the network interface name - it probably starts with `en`:
```
$ basename -a /sys/class/net/*
enxb827eb6e32c9
lo
vpns0
wlan0
```

Then issue the following *iptables* command, with the
interface name specifed for parameter `-o`:
```
sudo iptables -t nat -A POSTROUTING -o enxb827eb6e32c9 -j MASQUERADE
```

To make this update permanent, install *iptables-persistant*:
* when prompted, choose **Yes** save IPv4 rules
* when prompted, choose **Yes** save IPv6 rules
```
sudo apt install iptables-persistent -y
```

#### Future work?

possibly open port 443 in iptables?
```
sudo iptables -I INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -I INPUT -p udp --dport 443 -j ACCEPT
````

possibly use UFW rules to do things?
* UFW before.rules for IP masquerading instead of `iptables` commands?
* need to enable forwarding in UFW version of sysctl (overrides somehow?)
* http://manpages.ubuntu.com/manpages/precise/en/man8/ufw-framework.8.html
* hints for ufw? https://gist.github.com/luginbash/52e745ab46cdf46b9061

enable TCP BBR congestion control? [reference](https://www.linuxbabe.com/ubuntu/enable-google-tcp-bbr-ubuntu)
```
...
 # TCP and UDP port number
 tcp-port = 443
-udp-port = 443
+#udp-port = 443
```







**working here**
----

### VNC Server (*tightvncserver*)

> **TODO** check out `x11vnc` as possibly much better 

> *FUTURE: possibly use Google Chrome Remote Desktop for screen sharing?
> As of 2018-10-31, share feature is not available for this platform.*

> *FUTURE: share HDMI desktop session by using `x11vnc` server instead?*
> * https://raspberrypi.stackexchange.com/questions/28369/how-to-control-pi-hdmi-output-from-laptop-via-vnc?rq=1
> * https://wiki.xdroop.com//space/Linux/x11vnc+setup
> * https://serverfault.com/questions/27044/how-to-vnc-into-an-existing-x-session
> * https://askubuntu.com/questions/107239/vnc-with-current-desktop

> *Follow up on : https://askubuntu.com/questions/611544/mate-desktop-weird-red-icons-in-top-right-corner-how-to-remove-fix?rq=1*

Install *tightvncserver*:
```
sudo apt install tightvncserver
```

Configure using *vncserver* command (as admin user, not root):
```
vncserver
```
* Specify a password 
* Optionally, specify a view-only password

Now, test the connection over SSH:
* Establish a tunnel: `ssh user@server.tld -L 5901:localhost:5901`
* Connect to `127.0.0.1:5901` using compatible viewer 
  (such as [VNC Viewer](https://www.realvnc.com/en/connect/download/viewer/))

Should work OK. Finally, create a *systemd* service file:
```
sudo nano /etc/systemd/system/vncserver@.service
```
```
[Unit]
Description=Start TightVNC server at startup
After=syslog.target network.target

[Service]
Type=forking
User=lar
Group=lar
WorkingDirectory=/home/lar

PIDFile=/home/lar/.vnc/%H:%i.pid
ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
ExecStart=/usr/bin/vncserver :%i
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
```

Enable and start the new service:
```
sudo systemctl daemon-reload
sudo systemctl enable vncserver@1.service
sudo systemctl start vncserver@1
sudo systemctl status vncserver@1
```

References:
* <https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-vnc-on-ubuntu-18-04>


### Network UPS Tools (*nut*)

Install *nut*:
```
sudo apt install nut -y
```

Ensure UPS is plugged in via USB. Add basic config options:
> *Use the [Hardware compatibility list](https://networkupstools.org/stable-hcl.html)
> to identify the correct driver type for your UPS.*
```
sudo nano /etc/nut/ups.conf
```
```diff
+[ups]
+        driver = usbhid-ups
+        port = auto
+        desc = "Data system UPS"
```

Expose the service to the local area network:
```
sudo nano /etc/nut/upsd.conf
```
```diff
 # =======================================================================
 # LISTEN <address> [<port>]
 # LISTEN 127.0.0.1 3493
 # LISTEN ::1 3493
+LISTEN 0.0.0.0 3493
 #
```

Finally, enable the service:
```
sudo nano /etc/nut/nut.conf
```
```diff
-MODE=none
+MODE=netserver
```
```
sudo systemctl restart nut-server.service
```

#### Graphical UPS Monitor (*NUT-Monitor*)

It is recommended to have *NUT-Monitor* installed so desktop users can easily
review the UPS status.
```
sudo apt install nut-monitor -y
```

Launch the program from the *Applications > Internet* menu.



### FTP Server (*vsftpd*)

Install so the Conext Combox has somewhere to push event log files?
* https://www.digitalocean.com/community/tutorials/how-to-set-up-vsftpd-for-a-user-s-directory-on-ubuntu-16-04
* https://help.ubuntu.com/lts/serverguide/ftp-server.html

Probably better approach: enable FTP service on NAS unit (Synology DS218?)


### Network Time Protocol (*ntpd*)

Probably already installed -> enable stats and configure for local network






---
> *v-- this section put on hold --v*





### Enable the firewall

Ref: <https://www.digitalocean.com/community/tutorials/how-to-setup-a-firewall-with-ufw-on-an-ubuntu-and-debian-cloud-server> 

Set to manually installed:
```
sudo apt install ufw
```

Then apply some default rules:
```
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh

```

As other programs get installed, allow them through too:

| Description | Rule |
|-------------|------|
| VPN server (*ocserv*)         | `allow https` |
| email relay (*postfix*)       | `allow smtp`  |
| VNC server (*tightvncserver*) | 5901/tcp? |
| network UPS tools (*nut*)     | 3493 |

* probably need to enable 443/udp for *ocserv*?





---

## Other things to look into

### Install other useful packages

Add ability to connect back to WSU VPN (Cisco AnyConnect protocol):
```
sudo apt install network-manager-openconnect-gnome -y
```

#### Fallback static IP on eth0?

Just in case router isn't present and can't assign DHCP reservation?... Give
unit a static IP so that *postfix* continues to operate?


#### Mate "Power Statistics" panel

* observed on this panel: `cannot enable timerstats`
    * symptoms mirror: https://bugzilla.redhat.com/show_bug.cgi?id=1427621
        * basically `/proc/timer_stats` is no longer a valid file but *upower*
          continues to rely on it?


