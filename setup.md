# Setup Details

## Hardware

The host is a Raspberry Pi 3 with class 10 SD card installed in a plastic case
for basic protection. It's powered through an on/off switch with a 2.5A/5V
power supply on a battery-backed UPS outlet.

* direct ethernet connection to the wifi router (not through a switch that could 
  potentially lose power)
* uninterruptible power supply (UPS) must be connected via USB


----

## Operating System

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
sudo /etc/default/cups
```
```
# do not load parallel port modules
LOAD_LP_MODULES=no
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

### Install necessary packages

The packages listed below will be necessary, either to setup or operations:
```
sudo apt install -y git
```




### Enable watchdog hardware

> **Work in progress**
> 
> **TODO:** revisit this section to finish setup

Refs:
* https://github.com/wsular/urbanova-aqnet-rpi-node/tree/master/doc/install
* https://stackoverflow.com/questions/37144547/setup-issues-using-the-hw-watchdog-with-systemd#46441311
* https://www.raspberrypi.org/forums/viewtopic.php?f=29&t=147501
* https://blog.kmp.or.at/watchdog-for-raspberry-pi/
* https://packages.ubuntu.com/search?suite=all&arch=any&keywords=watchdog


Install and enable the *watchdog* service to prevent system freezes:
```
sudo apt install watchdog -y
```
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

... possibly just use `systemctl enable watchdog`?





---

> *v-- this section put on hold --v*


### Boot Options

The server is intended for headless operation so to preserve system resources, 
have the computer boot into a terminal instead of the graphical desktop. 

> To start the desktop from the command line, run `startx`.
> 
> Graphical (virtual) desktops will be automatically be created for VNC users.

Use *raspi-config* to change the default boot type:
```
sudo raspi-config
```
```
Boot Options -> Desktop / CLI -> Console Text
```

Before exiting, trigger the *raspi-config* internal update tool. 


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





> *\^-- on hold --^*
---

### Other things to look into:


### Install other useful packages

Add ability to connect back to WSU VPN (Cisco AnyConnect protocol):
```
sudo apt install network-manager-openconnect-gnome -y
```


#### Mate "Power Statistics" panel

* observed on this panel: `cannot enable timerstats`
    * symptoms mirror: https://bugzilla.redhat.com/show_bug.cgi?id=1427621
        * basically `/proc/timer_stats` is no longer a valid file but *upower*
          continues to rely on it?





----

## Software

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






---
**<-- future: -->**

----


### Automatic Package Updates (*unattended-upgrades*)

Install *unattended-upgrades*:
```
sudo apt install unattended-upgrades
```

Verify configuration includes security updates...:
```
sudo nano /etc/apt.conf.d/50unattended-upgrades
```
```
// Automatically upgrade packages from these (origin:archive) pairs
Unattended-Upgrade::Allowed-Origins {
        "${distro_id}:${distro_codename}";
        "${distro_id}:${distro_codename}-security";
        // Extended Security Maintenance; doesn't necessarily exist for
        // every release and this system may not have it installed, but if
        // available, the policy for updates is such that unattended-upgrades
        // should also install from here by default.
        "${distro_id}ESM:${distro_codename}";
//      "${distro_id}:${distro_codename}-updates";
//      "${distro_id}:${distro_codename}-proposed";
//      "${distro_id}:${distro_codename}-backports";
};
```

> 2018-10-30 enabled `-updates` as well as `-security` packages, enabled
> option for automatic `autoremove`, and enabled automatic reboots @ 2AM

...and that automatic upgrades are enabled:
```
sudo nano /etc/apt/apt.conf.d/20auto-upgrades
```
```
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
```

Enable email reports to user "*root*" (messages will be automatically forwarded
by *postfix* to a monitored email address):
```
sudo nano /etc/apt.conf.d/50unattended-upgrades
```
```diff
 // Send email to this address for problems or packages upgrades
 // If empty or unset then no email is sent, make sure that you
 // have a working mail setup on your system. A package that provides
 // 'mailx' must be installed. E.g. "user@example.com"
-//Unattended-Upgrade::Mail "root";
+Unattended-Upgrade::Mail "root";
```

After confirming email reports work correctly, optionally change to only report
errors:
```
sudo nano /etc/apt.conf.d/50unattended-upgrades
```
```diff
 // Set this value to "true" to get emails only on errors. Default
 // is to always send a mail if Unattended-Upgrade::Mail is set
-//Unattended-Upgrade::MailOnlyOnError "true";
+Unattended-Upgrade::MailOnlyOnError "true";
```

References:
* https://help.ubuntu.com/lts/serverguide/automatic-updates.html


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


### VPN Server (*ocserv*)


> ***TODO***



### Email relay (*postfix*)

Ref: <https://devops.profitbricks.com/tutorials/configure-a-postfix-relay-through-gmail-on-ubuntu/>

Install *postfix* and follow prompts from package installer:
```
sudo apt install postfix
```
* Configure as *Satellite* site
* *Just provide hostname for FQDN - revisit later*
* Specify smtp server (*smtp.gmail.com*)

Enable SASL:
```
sudo nano /etc/postfix/main.cf
```
```diff
+smtp_use_tls = yes
+smtp_sasl_auth_enable = yes
+smtp_sasl_password_maps = hash:/etc/postfix/sasl/sasl_password
+smtp_sasl_security_options = noanonymous
+smtp_sasl_tls_security_options = noanonymous
```

Create credentials files and secure their file permissions:
> *For maximum security, you should use an 
> [app password](https://support.google.com/accounts/answer/185833?hl=en)
> instead of the account password.*
```
sudo nano /etc/postfix/sasl/sasl_password
```
```
smtp.gmail.com yourusername@gmail.com:password
```
```
sudo postmap /etc/postfix/sasl/sasl_password
sudo chown -R root:postfix /etc/postfix/sasl
sudo chmod 640 /etc/postfix/sasl/*
sudo chmod 750 /etc/postfix/sasl
```

Restart the service and test (*mail* is in *mailutils*):
```
sudo systemctl restart postfix
```
```
sudo apt install mailutils -y
echo "postfix test" | mail -s "test message" myemail@example.com
```

Now configure *postfix* as an open relay on the local area network. First,
add the LAN address (ex: 192.168.1.0/24) to the source network list. Then
enable listening on all interfaces (for simplicity, you could be more specific
too).
```
sudo nano /etc/postfix/main.cf
```
```diff
-mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
+mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 192.168.1.0/24
```
```dif
-inet_interfaces = loopback-only
+inet_interfaces = all
```

Finally, configure local mail forwarding using `/etc/aliases`
[[ref](https://unix.stackexchange.com/a/21582/160424)]:
```
sudo nano /etc/aliases
```
```diff
 # See man 5 aliases for format
 postmaster:    root
+root:   myadminuser
+myadminuser: myemail@example.com
```
```
sudo newaliases
```

Now test... somehow.


* https://blog.dantup.com/2016/04/setting-up-raspberry-pi-raspbian-jessie-to-send-email/
    * if hangs at start-up
* https://gist.github.com/dwilkie/41ae0c7acc48186e6058
    * hints on UFW rules
* https://www.linuxbabe.com/ubuntu/automatic-security-update-unattended-upgrades-ubuntu-18-04



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




