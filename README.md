# Porkbun PowerShell
A PowerShell script for updating DNS records on Porkbun.com based on the IP address assigned to a particular network adapter on the machine.

Typical use case is to update a DNS record for a particular domain to point to a server with a dynamically assigned IP address.

## Usage
### IPv4
```powershell
PS > .\Update-DnsRecord.ps1 -InterfaceAlias YOURADAPTERNAME -AddressFamily IPv4 -ApiKey APIKEY -ApiSecret APISECRET -Hostname YOURHOSTNAME.COM -Subdomain SUBDOMAIN -RecordType A
```

### IPv6
```powershell
PS > .\Update-DnsRecord.ps1 -InterfaceAlias YOURADAPTERNAME -AddressFamily IPv6 -ApiKey APIKEY -ApiSecret APISECRET -Hostname YOURHOSTNAME.COM -Subdomain SUBDOMAIN -RecordType AAAA
```

## Notes
This uses the DNS API provided by Porkbun documented [here](https://porkbun.com/api/json/v3/documentation).

This is a very simple script meant for personal use. Your mileage may vary.

### To add a scheduled task:
Simply open `taskschd.msc` and add a task to launch a program with the following:
- File: `powershell.exe`
- Arguments: `-ExecutionPolicy Bypass -File C:\Path\To\Update-DnsRecord.ps1 -AddressFamily IPv6 -InterfaceAlias "Your Network Interface" -Hostname "domain.here" -Subdomain "blah" -RecordType "AAAA" -ApiKey "blahblah" -ApiSecret "hunter2"`