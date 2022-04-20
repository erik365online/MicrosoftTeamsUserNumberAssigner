# Microsoft Teams User Number Assigner (TDR-UNA)
This small PowerShell-based tool is intended to help you with enabling users for Microsoft Teams Direct Routing.

The script opens a graphical user interface (GUI) to simplify a few basic enablement tasks. 
It's called the Teams Direct Routing User Number Assigner (TDR-UNA) and can be used to enable a single Teams User for Teams Direct Routing.
  
Use on your own risk.

![TDRUNA](https://github.com/erik365online/MicrosoftTeamsUserNumberAssigner/blob/main/TDRUNAV03.png?raw=true)

## Requirements and prerequisites
  - Recent PowerShell version
  - PowerShell Script Execution must be enabled (Get-/Set-ExecutionPolicy ...)
  - Microsoft Teams Module V4.2.0
  - Microsoft 365 Global Admin or Skype for Business Administrator

## Features V0.3
- GUI for Teams Direct Routing user enablement
- Connect to Microsoft Teams (only with device authentication, see PowerShell info after click on connect)
- Disconnect Microsoft Teams
- List all users
- Select a user
- Assign a phone number to a Teams Direct Routing user
- *Set a user's Teams Upgrade mode to TeamsOnly (deprected and removed V0.2 feature)*
- *Enable a user for Enterprise Voice (deprected and removed V0.2 feature)*
- *Enable a user for Hosted Voicemail (deprected and removed V0.2 feature)*
- *Enable a user for Enterprise Voice (removed V0.2 feature)*
- Assign a online voice routing policy
- Assign a calling policy
- Deleting user phone numbers (**new**) 

## Bugs, issues and limitations V0.3
- Not checking for assigned licsense sku or Assigned Plan for a listed or selected user
- No refresh of users after a change to a user was applied is implemented (disconnect, close, open, connect required)
- Even resource accounts are listed
- Changing resource account numbers is not implemented/supported (!)
- Deleting resource account phone numbers in not implemented	
- No code-signed script
	
## Bugs, issues and limitations V 0.3
- Not checking for assigned licsense sku or Assigned Plan for a listed or selected user
- No refresh of users after a change to a user was applied is implemented (disconnect, close, open, connect required)
- Even resource accounts are listed
- Changing resource account numbers is not implemented/supported (!)
- Deleting resource account phone numbers in not implemented
- No code-signed script

### Connect & Follow Erik365Online
**Blog: [https://www.erik365.blog](https://www.erik365.blog)**

**Twitter: [https://twitter.com/erik365online](https://twitter.com/erik365online)**
