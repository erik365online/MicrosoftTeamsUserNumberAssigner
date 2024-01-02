# Teams User Number Assigner (TDRUNA)
This small PowerShell-based tool is intended to help you with enabling users for Microsoft Teams Direct Routing.

The script opens a graphical user interface (GUI) to simplify a few basic enablement tasks. 
It's called the Teams Direct Routing User Number Assigner (TDR-UNA) and can be used to enable a single Teams User for Teams Direct Routing.
  
Use on your own risk.

![TDRUNA](/TDRUNA.png)

## Requirements and prerequisites
  - Recent PowerShell version
  - PowerShell Script Execution must be enabled (Get-/Set-ExecutionPolicy ...)
  - Microsoft Teams Module V4.2.0
  - Microsoft 365 Global Admin or Skype for Business Administrator

## Features V0.4
- GUI for Teams Direct Routing user enablement
- Connect to Microsoft Teams (only with device authentication)
- Disconnect Microsoft Teams
- List all users
- Select a user	
- Assign a phone number (direct routing)
- Release a phone number (direct routing)
- Assign a online voice routing policy
- Assign a calling policy
- Deleting user phone numbers (new) 

## Bugs, issues and limitations V0.4
- Not checking for assigned licsense sku or Assigned Plan for a listed or selected user
- No refresh of users after a change to a user was applied is implemented (disconnect, close, open, connect required)
- Resource accounts are listed
- Changing resource account numbers is not implemented/supported/tested
- Deleting resource account phone numbers in not implemented/supported/tested
- No code-signed script
- No certificate-based authentication (maybe in a future release)
- No application-based access token authentication (maybe in a future release)

### Connect & Follow Erik365Online
Blog: [https://www.erik365.blog](https://www.erik365.blog)
Mastodon [https://techhub.social/@erik365online](https://techhub.social/@erik365online)
Twitter: [https://twitter.com/erik365online](https://twitter.com/erik365online)
