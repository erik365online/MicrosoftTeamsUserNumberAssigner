# Microsoft Teams User Number Assigner
This small PowerShell-based tool is intended to help you with enabling users for Microsoft Teams Direct Routing.

The script opens a graphical user interface (GUI) to simplify a few basic enablement tasks. 
It's called the Teams Direct Routing User Number Assigner (TDR-UNA) and can be used to enable a single Teams User for Teams Direct Routing.
  
Use on your own risk.

## Requirements and prerequisites
  - Recent PowerShell version
  - PowerShell Script Execution must be enabled (Get-/Set-ExecutionPolicy ...)
  - Microsoft Teams Module V2.3.1 (tested)
  - Microsoft 365 Global Admin or Skype for Business Administrator

## Features V 0.2	
- GUI for Teams Direct Routing user enablement
- Connect to Microsoft Teams (only with modern authentication)
- Disconnect Microsoft Teams
- List all users (initial loading, after connect, might take some time depending on your user count)
- Select a user
- Set a user's Teams Upgrade mode to TeamsOnly
- Enable a user for Enterprise Voice
- Enable a user for Hosted Voicemail
- Enable a user for Enterprise Voice
- Assign a online voice routing policy
- Assign a calling policy
	
## Bugs, issues and limitations V 0.2
- Not checking for assigned licsense sku or Assigned Plan for a listed or selected user
- No refresh of users after a change to a user was applied is implemented (disconnect, close, open, connect required)
- Even resource accounts are listed
- Changing resource account numbers is not implemented/supported (!)
- Deleting resource account phone numbers in not implemented
- Deleting user phone numbers in not implemented 
- No code-signed script
