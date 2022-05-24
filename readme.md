> This project has been retired for a several reasons but overall because it's
> simpler to divide responsibilities between the data PC (Windows 10) and the
> Campbell Scientific data logger (CR1000). Also, the AmpliFi HD router now has
> a VPN of its own and that's sufficient for off-campus users to gain secure
> remote access.
> 
> On the data PC:
> * [Filezilla FTP Server](https://filezilla-project.org/)
> * Network time protocol ([Meinberg build for Windows](https://www.meinbergglobal.com/english/sw/ntp.htm))
> * [hMailServer](https://www.hmailserver.com/)
> * [CyberPower PowerPanel Business 4](https://www.cyberpowersystems.com/products/software/power-panel-business/)
>
> On the [data logger](https://github.com/wsular/rv-logger1):
> * GPS for time sync

----
# Research Van Utility Server

Basic utility server to support advanced features of the WSU LAR Research Van.
Core functionality includes:

* **GPS-enabled Network Time Protocol (NTP) server**  
  To provide local devices with a stratum 1 time source
* **Virtual Private Network (VPN) server**  
  To support remote access by users without requiring proprietary software
* **Email relay (SMTP) server**  
  To securely send emails from devices and software inside the van
* **Network UPS Tools (NUT) server**  
  To share the datacom uninterruptible power supply (UPS) with the data PC
* **VSFTPd File Transport Protocol (FTP) Server**  
  To support FTP streaming of log files from the power system controller
  (ComBox) and data table files from Campbell Scientific loggers, and for
  remote users to access data files.
* **Hardware watchdog**
  To automatically reset after unintended system halts
* and administration tools, including:
    * **System monitoring webpage**  
      To report server status and runtime statistics
    * **Firewall**  
      To prevent abuse of provided services by non-local clients
    * **Terminal session manager**  
      To provide a shared command line across disparate SSH logins
    * **Automatic package updates**  
      To ensure security-related updates are automatically installed

