# Computer-Search
This script is a command-line tool made to assist help desk technicians. It provides a quick centralized location for many management tasks such as network diagnostics, Active Directory computer management, system information retrieval and endpoint security operations through the use of an API (this info is redacted for privacy reasons)

# Functionality
Everything is menu driven. Menus include
- [Network options](#network-menu)
- [Systems options](#systems-menu)
- [Security options](#security-menu)

Additionally at the main menu you are able to check currently logged-in users, and offer remote assistance using Microsoft Remte Assistance (MSRA)

### Network Menu
network menu functionality includes
1. ping a computer
1. ping a computer continuously
1. copy a computer's IP address to your clipboard
1. copy a computer's MAC address to your clipboard

### Systems Menu
Systems menu functionality includes
1. save a computer name to your clipboard
1. get a computer's active directory groups
1. get a computer's uptime
1. get a computer's disk usage
1. get a computer's operating system (based on Active Directory field)
1. get a computer's bitlocker recover key
1. remotely reboot a computer

### Security Menu
The Security Menu requires an API key. If you have a key, then you have the options to:
1. log off the current user (this was specific to my use case and the automation I had in our XDR system)
1. check a computer's connection to XDR
1. isolate a computer
1. un-isolate a computer

# How to Use
To use this script you need to have an open PowerShell session running as Administrator. In your PowerShell session run the script followed by either an AD description or a computer name for example 
```powershell
.\path\to\script\computerSearch.ps1 "John Smith"
```
or 
```powershell
.\path\to\script\computerSearch.ps1 endpoint-name
```
Be aware that this script does use the PowerShell Active Directory Module, so if you don't have that installed already, you will need it. I would also recommend setting up an alias to the script to save yourself time and energy.
