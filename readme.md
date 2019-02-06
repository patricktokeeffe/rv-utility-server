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

