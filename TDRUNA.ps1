################################################################################
# Teams Direct Routing User Number Assigner (TDR-UNA)
################################################################################
<#
.SYNOPSIS
Teams Direct Routing User Number Assigner (TDR-UNA)

.DESCRIPTION
	Use on your own risk. The script opens a graphical user interface (GUI) to simplify a few basic enablement tasks. 
	It's called the Teams Direct Routing User Number Assigner (TDR-UNA) and can be used to enable a single Teams User for Teams Direct Routing.
	Use on your own risk.

  Features V0.3
	- GUI for Teams Direct Routing user enablement
	- Connect to Microsoft Teams (only with device authentication, see PowerShell info after click on connect)
	- Disconnect Microsoft Teams
	- List all users
	- Select a user
	- Set a user's Teams Upgrade mode to TeamsOnly (deprected and removed V0.2 feature)
	- Enable a user for Enterprise Voice (deprected and removed V0.2 feature)
	- Enable a user for Hosted Voicemail (deprected and removed V0.2 feature)
	- Enable a user for Enterprise Voice (removed V0.2 feature)
	- Assign a online voice routing policy
	- Assign a calling policy
	- Deleting user phone numbers (new) 

  Bugs, issues and limitations V0.3
	- Not checking for assigned licsense sku or Assigned Plan for a listed or selected user
 	- No refresh of users after a change to a user was applied is implemented (disconnect, close, open, connect required)
	- Even resource accounts are listed
	- Changing resource account numbers is not implemented/supported (!)
	- Deleting resource account phone numbers in not implemented	
	- No code-signed script

.EXAMPLE
C:\PS> .\TDR-UNA.ps1

.NOTES
Version:        0.3
Author:         Erik Kleefeldt
Date Creation:  08.01.2021 Initial script development
Date Update 1:	31.02.2021 Script development
Date Update 1:	21.03.2021 Check Teams Module V2 Adjustments
Date Update 2:	24.05.2021 Minor Adjustments
Date Update 3: 19.04.2021 Adjustments to run with Teams PowerShell Module Version 4.2.0

.LINK
https://erik365.blog
#>

################################################################################
# Loading external assemblies
################################################################################

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
try {
	Import-Module MicrosoftTeams	
}
catch {
	#Write-Host "There's no Microsoft Teams Module installed or it could not be imported." -ForegroundColor Red
	throw "There's no Microsoft Teams Module installed or it could not be imported. `n Please open PowerShell as an admin an run the Install-Module MicrosoftTeams cmdlet."
}
################################################################################
#Variables area (start declaration)
################################################################################
$Global:connected = "no"
$Global:userslistedonce = "no"
$Global:ovrpslistedonce = "no"
$Global:cpslistedonce = "no"

################################################################################
#Function area
################################################################################
#Close app on X
function FCloseForm{ 
	# $this parameter is equal to the sender (object)
	# $_ is equal to the parameter e (eventarg)

	# The CloseReason property indicates a reason for the closure :
	#   if (($_).CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing)

	#Sets the value indicating that the event should be canceled.
	($_).Cancel= $False
}
#Close app button
function FCloseOnClick {	
	Write-Host "App is being closed." -ForegroundColor Yellow
	$FMain.Close()
}
#Open Link on click in web browser
function OpenBlogOnClick {
	[Diagnostics.Process]::Start("https://www.erik365.blog","arguments")	
}
#Connect MS Teams
function ConnectTeamsOnClick {	
	try {			
		if ($Global:connected -ne "connected"){			
			#Connect Teams
			Write-Host "Connecting ..." -ForegroundColor Yellow						
			Write-Host "Please wait till connection is established ..." -ForegroundColor Yellow													
			
			Connect-MicrosoftTeams -UseDeviceAuthentication			

			$Global:connected = "connected"
			[void][System.Windows.Forms.MessageBox]::Show("Connected to Teams")	
			Write-Host "Connected." -ForegroundColor Yellow			
			Write-Host "Loading users and policies..." -ForegroundColor Yellow
			
			#Directly start to load users and policies after connect is done			
			ListUsers
			ListOVRPs
			ListCPs	
		}
		else{			
			[void][System.Windows.Forms.MessageBox]::Show("Already connected")
			Write-Host "Already Connected." -ForegroundColor Yellow
		}
	}
	catch {	
		$Global:connected = "no"		
		[void][System.Windows.Forms.MessageBox]::Show("Could not connect to Teams.`n Please ensure connectivity and Teams Module is installed.")
		Write-Host "Could connect to Teams. Please ensure Teams Module is installed." -ForegroundColor Red
	}
}
#Disconnect MS Teams
function DisconnectTeamsOnClick {	
	try {		
		if ($Global:connected -eq "connected"){			
			Write-Host "Disconnecting Teams" -ForegroundColor Yellow
			Disconnect-MicrosoftTeams -Verbose	
			[void][System.Windows.Forms.MessageBox]::Show("Disconnected")
			Write-Host "Disconnected" -ForegroundColor Yellow
			$Global:connected = "no"						
		}
		else {
			[void][System.Windows.Forms.MessageBox]::Show("Not connected")
		}		
	}
	catch {
		if ($Global:connected -eq "connected"){$Global:connected = "no"}
		else {
			[void][System.Windows.Forms.MessageBox]::Show("Not connected")
			Write-Host "Not connected" -ForegroundColor Red		
		}				
		[void][System.Windows.Forms.MessageBox]::Show("Could not disconnect sessions")
		Write-Host "Could not disconnect sessions" -ForegroundColor Red		
	}
}
#Get all teams user to populate dropdown list
function ListUsers {
	if ($Global:userslistedonce -ne "yes"){	
		try {
		$Global:userslistedonce = "yes"		
		$Global:Cselectuser.Items.Clear()
		Write-Host "Cleaning user list ..."	-ForegroundColor Yellow			
		Write-Host "Loading user list ..."	-ForegroundColor Yellow
		Write-host "Please wait, this can take some time depending on how many users you host on Teams..." -ForegroundColor Yellow
		#get users
		$Global:allusers = Get-CsOnlineUser
		#count users
		$Global:usercounter = ($Global:allusers).count
		$Global:ipb1 = 0 #progresscounter
		#populate dropdown list with upns and display progress bar			
		$Global:allusers | Sort-Object UserPrincipalName | ForEach-Object {
			#assuming that upn=primary smtp=primary sip address 
			#[void] $Global:Cselectuser.Items.Add($_.DisplayName)
			#[void] $Global:Cselectuser.Items.Add($_.SamAccountName)
			#[void] $Global:Cselectuser.Items.Add($_.SipAddress)
			[void] $Global:Cselectuser.Items.Add($_.UserPrincipalName)				
			Write-Progress -Activity "Loading in progress ..." -Status "Progress" -PercentComplete ((($Global:ipb1++) / $Global:usercounter) * 100)
			}
			#remove progress bar if done
			Write-Progress -Activity "Loading in progress ..." -Status "Ready" -Completed
		#set variable to no re-initialize the drop down by Add_Click(...) again								
		}
		catch {
			[void][System.Windows.Forms.MessageBox]::Show("Could not get Team users. `nPlease check connectivity and retry.")
			Write-Host "Could not get Team users. Please check connectivity and retry." -ForegroundColor Red
			$Global:userslistedonce = "no"			
		}			
	}
	else {
		#Do nothing to avoid re-loading items to the drop down
	}	
}
#Select user
function SelectUser {	
	try {	
        Write-Host "############# Selected User #############" -ForegroundColor Yellow
		$Global:selecteduser = $Global:Cselectuser.SelectedItem
		Write-Host $Global:selecteduser -ForegroundColor Yellow

		$Global:currentuser = (Get-CsOnlineUser "$Global:selecteduser")
		#$Global:currentuser | Format-List UserPrincipalName,SipAddress,OnpremLineUri,EnterpriseVoiceEnabled,HostedVoiceMail,OnlineVoiceRoutingPolicy,TeamsCallingPolicy,TeamsUpgradeEffectiveMode
		$Global:currentuser | Format-List UserPrincipalName,LineUri,OnlineVoiceRoutingPolicy,TeamsCallingPolicy,TenantDialPlan

		#Collect data into variables
		$Global:currentupn = ($Global:currentuser).UserPrincipalName
		$Global:currentsip = ($Global:currentuser).SipAddress
		$Global:currentlineuri = ($Global:currentuser).LineUri		
		#$Global:currentev = ($Global:currentuser).EnterpriseVoiceEnabled				
		#$Global:currenthvm = ($Global:currentuser).HostedVoiceMail
		<#if ($null -eq $Global:currenthvm){ 
			$Global:currenthvm = "Off" 
		}
		else { 
			#Do nothing 
		}#>
		$Global:currentovrp = ($Global:currentuser).OnlineVoiceRoutingPolicy
		#$Global:currenttup = ($Global:currentuser).TeamsUpgradeEffectiveMode						
		<#if ($null -eq $Global:currentovrp){ 
			$Global:currentovrp = "Global" 
		}
		else { 
			#Do nothing 
		}#>		
		$Global:currentcp = $Global:currentuser.TeamsCallingPolicy
		if ($null -eq $Global:currentcp){ 
			$Global:currentcp = "Global" 
		}
		else { 
			#Do nothing 
		}
		
		#Build nice output object
		$Global:currentuserobj = New-Object -TypeName psobject
		$Global:currentuserobj | Add-Member -MemberType NoteProperty -Name "UPN" -Value "$Global:currentupn"
		$Global:currentuserobj | Add-Member -MemberType NoteProperty -Name "SIP" -Value "$Global:currentsip"
		$Global:currentuserobj | Add-Member -MemberType NoteProperty -Name "LineUri" -Value "$Global:currentlineuri"
		#$Global:currentuserobj | Add-Member -MemberType NoteProperty -Name "EnterpriseVoice" -Value "$Global:currentev"
		#$Global:currentuserobj | Add-Member -MemberType NoteProperty -Name "HostedVM" -Value "$Global:currenthvm"
		$Global:currentuserobj | Add-Member -MemberType NoteProperty -Name "OnlineVoiceRoutingPolicy" -Value "$Global:currentovrp"
		$Global:currentuserobj | Add-Member -MemberType NoteProperty -Name "CallingPolicy" -Value "$Global:currentcp"
		#$Global:currentuserobj | Add-Member -MemberType NoteProperty -Name "TeamsUpgradeMode" -Value "$Global:currenttup"		
		#Show custom object
		$Global:currentuserobj.PSObject.Properties | ForEach-Object {
			$name = $_.Name 
			$value = $_.value
			Write-Host "$name = $value" -ForegroundColor Gray
		} 
	}
	catch { 
		[void][System.Windows.Forms.MessageBox]::Show("No user could be selected. Please select a user.") 
		Write-Host "No user could be selected. Please select a user." -ForegroundColor Red
	}
}

#Assign phone number (DIRECT ROUTING)
function AssignLineUri {
	try { 
		$Global:lineuri = $Global:Tenterlineuri.Text
		#Set-CsUser -Identity $Global:selecteduser -OnPremLineURI $Global:lineuri
		Set-CsPhoneNumberAssignment -Identity "$Global:selecteduser" -PhoneNumber "$Global:lineuri" -PhoneNumberType DirectRouting
		
		[void][System.Windows.Forms.MessageBox]::Show("$Global:lineuri assigned to $Global:selecteduser.")
		Write-Host "$Global:lineuri assigned to $Global:selecteduser." -ForegroundColor Yellow
		}
	catch { 
		[void][System.Windows.Forms.MessageBox]::Show("Could not assign phone number. `nPlease check´n $Global:lineuri ´nif the value is correct. `nIt must be tel:+49..123.")	
		Write-Host "Could not assign phone number. Please check $Global:lineuri if the value is correct. It must be +49..123." -ForegroundColor Red
	}
}
#Release phone number (DIRECT ROUTING)
function ReleaseNumber {
	try { 
		Remove-CsPhoneNumberAssignment -Identity "$Global:selecteduser" -RemoveAll 
		Write-Host "Phone number for $Global:selecteduser was removed." -ForegroundColor Yellow
		[void][System.Windows.Forms.MessageBox]::Show("$Global:selecteduser phone number removed and EV disabled.")
		}
	catch { 
		[void][System.Windows.Forms.MessageBox]::Show("Could not remove phone number for $Global:selecteduser.")	
		Write-Host "Could not remove phone number for $Global:selecteduser." -ForegroundColor Red
	}
}
#List online voice routing policis
function ListOVRPs {
	if ($Global:ovrpslistedonce -ne "yes"){
		$Global:ovrpslistedonce = "yes"
		$Global:Cassignvrp.Items.Clear()
		Write-Host "Loading online voice routing policies..." -ForegroundColor Yellow
		try {
			$Global:allovrps = Get-CsOnlineVoiceRoutingPolicy
			$Global:ovrpscounter = ($Global:allovrps).count
			$Global:ipb2 = 0 #progresscounter
			$Global:allovrps | ForEach-Object { 
				[void] $Global:Cassignvrp.Items.Add($_.Identity) 
				Write-Progress -Activity "Loading in online voice routing policies ..." -Status "Progress" -PercentComplete ((($Global:ipb2++) / $Global:ovrpscounter) * 100)
			}		
			Write-Progress -Activity "Loading in online voice routing policies ..." -Status "Ready" -Completed			
			#return $Global:ovrpslistedonce						
		}
		catch { 
			[void][System.Windows.Forms.MessageBox]::Show("Could not find any online voice routing policy.") 
			Write-Host "Could not find any online voice routing policy." -ForegroundColor Red
			$Global:ovrpslistedonce = "no"
		}				
	}
	else {
		#Do nothing
	}
}
#Select online voice routing policy
function SelectOVRP {
		try { 
			$Global:userovrp = $Global:Cassignvrp.SelectedItem
			Write-Host "Selected online voice routing policy: $Global:userovrp" -ForegroundColor Yellow			
		}
		catch { 
			[void][System.Windows.Forms.MessageBox]::Show("Could not select online voice routing policy.") 
			Write-Host "Could not select online voice routing policy $Global:userovrp." -ForegroundColor Red
		}			
}
#Assign online voice routing policy
function AssignOVRP {
	try { 
		if($Global:userovrp -eq "Global"){
			Grant-CsOnlineVoiceRoutingPolicy -Identity $Global:selecteduser -PolicyName $null
			Write-Host "Assign global OVRP to $Global:selecteduser" -ForegroundColor Yellow
		}
		else {
			Grant-CsOnlineVoiceRoutingPolicy -Identity $Global:selecteduser -PolicyName $Global:userovrp	
			Write-Host "Assign $Global:userovrp to $Global:selecteduser" -ForegroundColor Yellow
		}		
	}
	catch { 
		[void][System.Windows.Forms.MessageBox]::Show("Could not assign online voice routing policy.") 
		Write-Host "Could not assign online voice routing policy to $Global:selecteduser." -ForegroundColor Red
	}			
}
#List calling policis
function ListCPs {
	if ($Global:cpslistedonce -ne "yes"){
		Write-Host "Loading calling policies..." -ForegroundColor Yellow
		try {
			$Global:cpslistedonce = "yes"
			$Global:allcallingpolicies = Get-CsTeamsCallingPolicy
			$Global:cpscounter = ($Global:allcallingpolicies).count
			$Global:ipb3 = 0 #progresscounter
			$Global:allcallingpolicies | ForEach-Object {
				[void] $Global:Cassigncp.Items.Add($_.Identity) 
				Write-Progress -Activity "Loading in calling policies ..." -Status "Progress" -PercentComplete ((($Global:ipb3++) / $Global:cpscounter) * 100)
			}
			Write-Progress -Activity "Loading in calling policies ..." -Status "Ready" -Completed	
		}
		catch { 
			[void][System.Windows.Forms.MessageBox]::Show("Could not find any calling policy.") 
			Write-Host "Could not find any calling policy." -ForegroundColor Red
			$Global:cpslistedonce = "no"
		}
	}
	else {
		#Do nothing
	}
}
#Select calling policy
function SelectCP {
	try {  
		$Global:usercp = $Global:Cassigncp.SelectedItem	
		Write-Host "Selected calling policy: $Global:usercp" -ForegroundColor Yellow	
	}
	catch { 
		[void][System.Windows.Forms.MessageBox]::Show("Could not select calling policy.") 
		Write-Host "Could not select calling policy $Global:usercp." -ForegroundColor Red
	}		
}
#Assign calling policy
function AssignCP {
	try { 
			if ($Global:usercp -eq "Global"){
				Grant-CsTeamsCallingPolicy -Identity $Global:selecteduser -PolicyName $null
				Write-Host "Assign global calling policy to $Global:selecteduser" -ForegroundColor Yellow
			}
			else {
				Grant-CsTeamsCallingPolicy -Identity $Global:selecteduser -PolicyName $Global:usercp
				Write-Host "Assign calling policy $Global:usercp to $Global:selecteduser" -ForegroundColor Yellow
			}
			
		}
	catch { 
		[void][System.Windows.Forms.MessageBox]::Show("Could not assign calling policy $Global:usercp to $Global:selecteduser.")
		Write-Host "Could not assign calling policy $Global:usercp to $Global:selecteduser." -ForegroundColor Yellow 
	}		
}
################################################################################
#Form assembly area
################################################################################
function global:GenerateForm {
	#Form assembly
	$FMain = New-Object System.Windows.Forms.Form
	#$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState

	$Bconnectteams = New-Object System.Windows.Forms.Button
	$Bdisconnectteams = New-Object System.Windows.Forms.Button
	$Bclose = New-Object System.Windows.Forms.Button
	$Global:Cselectuser = New-Object System.Windows.Forms.ComboBox
	$Lselectuser = New-Object System.Windows.Forms.Label
	$Lassignvrp = New-Object System.Windows.Forms.Label
	$Global:Cassignvrp = New-Object System.Windows.Forms.ComboBox
	$Lassigncp = New-Object System.Windows.Forms.Label
	$Global:Cassigncp = New-Object System.Windows.Forms.ComboBox
	#$Lenterprisevoice = New-Object System.Windows.Forms.Label
	$Global:Tenterlineuri = New-Object System.Windows.Forms.TextBox
	$Ltermsofuse = New-Object System.Windows.Forms.Label
	#$Lhostedvoicemail = New-Object System.Windows.Forms.Label
	$Lenterlineuri = New-Object System.Windows.Forms.Label
	#$lenableteamsonly = New-Object System.Windows.Forms.Label
	#$Bsetteamsonly = New-Object System.Windows.Forms.Button
	$Breleasenumber = New-Object System.Windows.Forms.Button
	#$Benablevm = New-Object System.Windows.Forms.Button
	$Bassignnumber = New-Object System.Windows.Forms.Button
	$Bassignvrp = New-Object System.Windows.Forms.Button
	$Bassigncp = New-Object System.Windows.Forms.Button
	$Lreleasenumber = New-Object System.Windows.Forms.Label
	$Lreleasenotes = New-Object System.Windows.Forms.Label
	$LLerik365blog = New-Object System.Windows.Forms.LinkLabel
	
	# Bconnectteams	
	$Bconnectteams.Location = New-Object System.Drawing.Point(10, 10)
	$Bconnectteams.Name = "Bconnectteams"
	$Bconnectteams.Size = New-Object System.Drawing.Size(104, 20)
	$Bconnectteams.TabIndex = 0
	$Bconnectteams.Text = "Connect Teams"
	$Bconnectteams.UseVisualStyleBackColor = $true
	$Bconnectteams.Add_Click( { ConnectTeamsOnClick } )

	# Bdisconnectteams
	$Bdisconnectteams.Location = New-Object System.Drawing.Point(400, 10)
	$Bdisconnectteams.Name = "Bdisconnectteams"
	$Bdisconnectteams.Size = New-Object System.Drawing.Size(104, 20)
	$Bdisconnectteams.TabIndex = 1
	$Bdisconnectteams.Text = "Disconnect Teams"
	$Bdisconnectteams.UseVisualStyleBackColor = $true
	$Bdisconnectteams.Add_Click( { DisconnectTeamsOnClick } )

	# Bclose
	$Bclose.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
	$Bclose.Location = New-Object System.Drawing.Point(510, 10)
	$Bclose.Name = "Bclose"
	$Bclose.Size = New-Object System.Drawing.Size(104, 20)
	$Bclose.TabIndex = 2
	$Bclose.Text = "Close"
	$Bclose.UseVisualStyleBackColor = $true
	$Bclose.Add_Click( { FCloseOnClick } )

	# Cselectuser
	$Global:Cselectuser.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$Global:Cselectuser.FormattingEnabled = $true
	$Global:Cselectuser.Location = New-Object System.Drawing.Point(148, 39)
	$Global:Cselectuser.MaxDropDownItems = 10
	$Global:Cselectuser.Name = "Cselectuser"
	$Global:Cselectuser.Size = New-Object System.Drawing.Size(356, 21)
	$Global:Cselectuser.Sorted = $true
	$Global:Cselectuser.TabIndex = 3
	#$Global:Cselectuser.Add_Click( { ListUsers } ) #reinitializes, readds etc.
	#ListUsers
	$Global:Cselectuser.Add_SelectedIndexChanged( { SelectUser } )

	# Lselectuser
	$Lselectuser.AutoSize = $true
	$Lselectuser.Location = New-Object System.Drawing.Point(12, 42)
	$Lselectuser.Name = "Lselectuser"
	$Lselectuser.Size = New-Object System.Drawing.Size(60, 13)
	$Lselectuser.TabIndex = 4
	$Lselectuser.Text = "Select user"
	
	# Lassignvrp
	$Lassignvrp.AutoSize = $true
	$Lassignvrp.Location = New-Object System.Drawing.Point(12, 84)
	$Lassignvrp.Name = "Lassignvrp"
	$Lassignvrp.Size = New-Object System.Drawing.Size(132, 13)
	$Lassignvrp.TabIndex = 6
	$Lassignvrp.Text = "Voice routing policy"

	# Cassignvrp
	$Global:Cassignvrp.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$Global:Cassignvrp.FormattingEnabled = $true
	$Global:Cassignvrp.Location = New-Object System.Drawing.Point(148, 84)
	$Global:Cassignvrp.Name = "Cassignvrp"
	$Global:Cassignvrp.Size = New-Object System.Drawing.Size(356, 21)
	$Global:Cassignvrp.TabIndex = 5
	#$Global:Cassignvrp.Add_Click( { ListOVRPs } )
	$Global:Cassignvrp.Add_SelectedIndexChanged( { SelectOVRP } )

	# Lassigncp
	$Lassigncp.AutoSize = $true
	$Lassigncp.Location = New-Object System.Drawing.Point(12, 105)
	$Lassigncp.Name = "Lassigncp"
	$Lassigncp.Size = New-Object System.Drawing.Size(101, 13)
	$Lassigncp.TabIndex = 8
	$Lassigncp.Text = "Calling policy"

	# Cassigncp
	$Global:Cassigncp.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$Global:Cassigncp.FormattingEnabled = $true
	$Global:Cassigncp.Location = New-Object System.Drawing.Point(148, 105)
	$Global:Cassigncp.Name = "Cassigncp"
	$Global:Cassigncp.Size = New-Object System.Drawing.Size(356, 21)
	$Global:Cassigncp.TabIndex = 7
	#$Global:Cassigncp.Add_Click( { ListCPs } )
	$Global:Cassigncp.Add_SelectedIndexChanged( { SelectCP } )
	
	# Global:Tenterlineuri
	$Global:Tenterlineuri.Location = New-Object System.Drawing.Point(148, 63)
	$Global:Tenterlineuri.Name = "Tenterlineuri"
	$Global:Tenterlineuri.Size = New-Object System.Drawing.Size(356, 20)
	$Global:Tenterlineuri.TabIndex = 10
	try {
		if (($null -eq $Global:currentlineuri) -or ($Global:currentlineuri -eq " ")){ $Global:Tenterlineuri.Text = "e.g. +49711987456123" }
		else { $Global:Tenterlineuri.Text = "$Global:currentlineuri" }
	}
	catch { $Global:Tenterlineuri.Text = "e.g. +49711987456123" }	

	# Ltermsofuse
	$Ltermsofuse.AutoSize = $true
	$Ltermsofuse.Font = New-Object System.Drawing.Font("Arial", 9,[System.Drawing.FontStyle]::Italic,[System.Drawing.GraphicsUnit]::Point, 0)
	$Ltermsofuse.ForeColor = [System.Drawing.Color]::FromArgb(200,0,0)
	$Ltermsofuse.Location = New-Object System.Drawing.Point(145, 10)
	$Ltermsofuse.Name = "Ltermsofuse"
	$Ltermsofuse.Size = New-Object System.Drawing.Size(152, 15)
	$Ltermsofuse.TabIndex = 11
	$Ltermsofuse.Text = "Terms of use: Use on own risk."
	
	# Lenterlineuri
	$Lenterlineuri.AutoSize = $true
	$Lenterlineuri.Location = New-Object System.Drawing.Point(12, 63)
	$Lenterlineuri.Name = "Lenterlineuri"
	$Lenterlineuri.Size = New-Object System.Drawing.Size(77, 13)
	$Lenterlineuri.TabIndex = 15
	$Lenterlineuri.Text = "Enter Line URI"

	# Lreleasenumber
	$Lreleasenumber.AutoSize = $true
	$Lreleasenumber.Location = New-Object System.Drawing.Point(12, 126)
	$Lreleasenumber.Name = "Lenterlineuri"
	$Lreleasenumber.Size = New-Object System.Drawing.Size(100, 13)
	$Lreleasenumber.TabIndex = 15
	$Lreleasenumber.Text = "Remove Line URI"

	# Breleasenumber
	$Breleasenumber.Location = New-Object System.Drawing.Point(148, 126)
	$Breleasenumber.Name = "Breleasenumber"
	$Breleasenumber.Size = New-Object System.Drawing.Size(200, 20)
	$Breleasenumber.TabIndex = 19
	$Breleasenumber.Text = "Release Phone Number"
	$Breleasenumber.UseVisualStyleBackColor = $true
	$Breleasenumber.Add_Click( { ReleaseNumber } )

	# Bassignnumber
	$Bassignnumber.Location = New-Object System.Drawing.Point(510, 63)
	$Bassignnumber.Name = "Bassignnumber"
	$Bassignnumber.Size = New-Object System.Drawing.Size(100, 20)
	$Bassignnumber.TabIndex = 21
	$Bassignnumber.Text = "Assign"
	$Bassignnumber.UseVisualStyleBackColor = $true
	$Bassignnumber.Add_Click( { AssignLineUri } )
	
	# Bassignvrp
	$Bassignvrp.Location = New-Object System.Drawing.Point(510, 84)
	$Bassignvrp.Name = "Bassignvrp"
	$Bassignvrp.Size = New-Object System.Drawing.Size(100, 20)
	$Bassignvrp.TabIndex = 22
	$Bassignvrp.Text = "Assign"
	$Bassignvrp.UseVisualStyleBackColor = $true
	$Bassignvrp.Add_Click( { AssignOVRP } )
	
	# Bassigncp
	$Bassigncp.Location = New-Object System.Drawing.Point(510, 105)
	$Bassigncp.Name = "Bassigncp"
	$Bassigncp.Size = New-Object System.Drawing.Size(100, 20)
	$Bassigncp.TabIndex = 23
	$Bassigncp.Text = "Assign"
	$Bassigncp.UseVisualStyleBackColor = $true
	$Bassigncp.Add_Click( { AssignCP } )

	# Lreleasenotes
	$Lreleasenotes.AutoSize = $true
	$Lreleasenotes.Font = New-Object System.Drawing.Font("Arial", 9,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point, 0)
	$Lreleasenotes.ForeColor = [System.Drawing.Color]::Green
	$Lreleasenotes.Location = New-Object System.Drawing.Point(12, 168)
	$Lreleasenotes.Name = "Lreleasenotes"
	$Lreleasenotes.Size = New-Object System.Drawing.Size(155, 15)
	$Lreleasenotes.TabIndex = 25
	$Lreleasenotes.Text = "V 0.3 Erik Kleefeldt April 2022"

	# LLerik365blog
	$LLerik365blog.AutoSize = $true
	$LLerik365blog.Font = New-Object System.Drawing.Font("Arial", 9,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point, 0)
	$LLerik365blog.Location = New-Object System.Drawing.Point(480, 168)
	$LLerik365blog.Name = "LLerik365blog"
	$LLerik365blog.Size = New-Object System.Drawing.Size(101, 13)
	$LLerik365blog.TabIndex = 26
	$LLerik365blog.TabStop = $true
	$LLerik365blog.Text = "Visit www.erik365.blog"
	$LLerik365blog.Add_Click( { OpenBlogOnClick } )
	
	# FMain
	$FMain.BackgroundImageLayout = [System.Windows.Forms.ImageLayout]::None
	$FMain.ClientSize = New-Object System.Drawing.Size(620, 189)
	$FMain.Controls.Add($LLerik365blog)
	$FMain.Controls.Add($Lreleasenotes)
	#$FMain.Controls.Add($Lshouldbeonbydefault)
	$FMain.Controls.Add($Bassigncp)
	$FMain.Controls.Add($Bassignvrp)
	$FMain.Controls.Add($Bassignnumber)
	$FMain.Controls.Add($Lreleasenumber)
	$FMain.Controls.Add($Breleasenumber)
	#$FMain.Controls.Add($Bsetteamsonly)
	#$FMain.Controls.Add($lenableteamsonly)
	$FMain.Controls.Add($Lenterlineuri)
	#$FMain.Controls.Add($Lhostedvoicemail)
	$FMain.Controls.Add($Global:Tenterlineuri)
	#$FMain.Controls.Add($Lenterprisevoice)
	$FMain.Controls.Add($Lassigncp)
	$FMain.Controls.Add($Global:Cassigncp)
	$FMain.Controls.Add($Lassignvrp)
	$FMain.Controls.Add($Global:Cassignvrp)
	$FMain.Controls.Add($Lselectuser)
	$FMain.Controls.Add($Global:Cselectuser)
	$FMain.Controls.Add($Bclose)
	$FMain.Controls.Add($Bdisconnectteams)
	$FMain.Controls.Add($Ltermsofuse)
	$FMain.Controls.Add($Bconnectteams)
	$FMain.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
	$FMain.Name = "FMain"
	$FMain.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
	$FMain.Text = "Erik365Online - Teams Direct Routing User Number Assigner V0.3"
	$FMain.Topmost = $true
	$FMain.Add_FormClosing( { FCloseForm } )
	$FMain.Add_Shown({$FMain.Activate()})
	#Initial form state
	#$InitialFormWindowState = $FMain.WindowState	
	#Intiate OnLoad event to correct the initial state of the form
	#$FMain.add_Load( { keepformok } )

	#$Result=$FMain.ShowDialog()
	[void]$FMain.ShowDialog()

	# Release the Form
	$FMain.Dispose()
}

#Call the form function
global:GenerateForm
