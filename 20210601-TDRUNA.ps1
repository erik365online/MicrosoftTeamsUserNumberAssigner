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

  Features V0.2
	- GUI for Teams Direct Routing user enablement
	- Connect to Microsoft Teams (only with modern authentication)
	- Disconnect Microsoft Teams
	- List all users
	- Select a user
	- Set a user's Teams Upgrade mode to TeamsOnly
	- Enable a user for Enterprise Voice
	- Enable a user for Hosted Voicemail
	- Enable a user for Enterprise Voice
	- Assign a online voice routing policy
	- Assign a calling policy

  Bugs, issues and limitations V0.2
	- Not checking for assigned licsense sku or Assigned Plan for a listed or selected user
 	- No refresh of users after a change to a user was applied is implemented (disconnect, close, open, connect required)
	- Even resource accounts are listed
	- Changing resource account numbers is not implemented/supported (!)
	- Deleting resource account phone numbers in not implemented
	- Deleting user phone numbers in not implemented 
	- No code-signed script

.EXAMPLE
C:\PS> .\TDR-UNA.ps1

.NOTES
Version:        0.2
Author:         Erik Kleefeldt
Date Creation:  08.01.2021 Initial script development
Date Update 1:	31.02.2021 Script development
Date Update 1:	21.03.2021 Check Teams Module V2 Adjustments
Date Update 2:	24.05.2021 Minor Adjustments

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
	[Diagnostics.Process]::Start("https://erik365.blog","arguments")	
}
#Connect MS Teams / SFB Session
function ConnectTeamsOnClick {	
	try {			
		if ($Global:connected -ne "connected"){			
			#Connect Teams
			Write-Host "Connecting ..." -ForegroundColor Yellow						
			Write-Host "Please wait till connection is established ..." -ForegroundColor Yellow													
			
			Connect-MicrosoftTeams			

			$Global:connected = "connected"
			[void][System.Windows.Forms.MessageBox]::Show("Connected to Teams")	
			Write-Host "Connected." -ForegroundColor Yellow			
			Write-Host "Loading users and policies..." -ForegroundColor Yellow
			
			#Directly start to load users and policies after connect is done			
			#Start-Sleep -Seconds 15
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
		$Global:currentuser | Format-List UserPrincipalName,SipAddress,OnpremLineUri,EnterpriseVoiceEnabled,HostedVoiceMail,OnlineVoiceRoutingPolicy,TeamsCallingPolicy,TeamsUpgradeEffectiveMode

		#Collect data into variables
		$Global:currentupn = ($Global:currentuser).UserPrincipalName
		$Global:currentsip = ($Global:currentuser).SipAddress
		$Global:currentlineuri = ($Global:currentuser).OnpremLineUri		
		$Global:currentev = ($Global:currentuser).EnterpriseVoiceEnabled				
		$Global:currenthvm = ($Global:currentuser).HostedVoiceMail
		if ($null -eq $Global:currenthvm){ 
			$Global:currenthvm = "Off" 
		}
		else { 
			#Do nothing 
		}
		$Global:currentovrp = ($Global:currentuser).OnlineVoiceRoutingPolicy
		$Global:currenttup = ($Global:currentuser).TeamsUpgradeEffectiveMode						
		if ($null -eq $Global:currentovrp){ 
			$Global:currentovrp = "Global" 
		}
		else { 
			#Do nothing 
		}		
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
		$Global:currentuserobj | Add-Member -MemberType NoteProperty -Name "EnterpriseVoice" -Value "$Global:currentev"
		$Global:currentuserobj | Add-Member -MemberType NoteProperty -Name "HostedVM" -Value "$Global:currenthvm"
		$Global:currentuserobj | Add-Member -MemberType NoteProperty -Name "OnlineVoiceRoutingPolicy" -Value "$Global:currentovrp"
		$Global:currentuserobj | Add-Member -MemberType NoteProperty -Name "CallingPolicy" -Value "$Global:currentcp"
		$Global:currentuserobj | Add-Member -MemberType NoteProperty -Name "TeamsUpgradeMode" -Value "$Global:currenttup"		
		#Show custom object
		$Global:currentuserobj

		<#
		#Display assigned online voice routing policy in combobox
		$Global:ipb4 = 0
		$Global:Cassignvrp.Items | ForEach-Object {			
			if ($_ -eq $Global:currentovrp){
				$Global:currentlyassignedovrpno = $Global:ipb4
				$Global:Cassignvrp.Item.SetSelected($Global:currentlyassignedovrpno,$true)
			}
			else{
				#Do nothing
			}
			$Global:ipb4++
		}

		#Display assigned calling policy in combobox
		$Global:ipb5 = 0
		$Global:Cassigncp.Items | ForEach-Object {			
			if ($_ -eq $Global:currentcp){
				$Global:currentlyassignedcpno = $Global:ipb5
				$Global:Cassigncp.SetSelected($Global:currentlyassignedcpno,$true)
			}
			else{
				#Do nothing
			}
			$Global:ipb5++
		}#>
		
	}
	catch { 
		[void][System.Windows.Forms.MessageBox]::Show("No user could be selected. Please select a user.") 
		Write-Host "No user could be selected. Please select a user." -ForegroundColor Red
	}
}
#Set Teams Upgrade
function EnableTeamsOnly {
	try {
		if (($null -ne $Global:selecteduser) -or ($Global:currenttup -ne "TeamsOnly") ){ 
			Grant-CsTeamsUpgradePolicy -PolicyName UpgradeToTeams -Identity $Global:selecteduser
			Write-Host "Selected user: $Global:currentupn upgraded. This can take some time."
			[void][System.Windows.Forms.MessageBox]::Show("Upgraded. This can take some time.")
		}
		else { 
			[void][System.Windows.Forms.MessageBox]::Show("User value is null or already TeamsOnly.")
			Write-Host "User value is null or already TeamsOnly." -ForegroundColor Red
			}
	}
	catch {	
		[void][System.Windows.Forms.MessageBox]::Show("User could not be upgrade to TeamsOnly.")
		Write-Host "User could not be upgrade to TeamsOnly." -ForegroundColor Red
 	}
	
}
#Enable Enterprise Voice
function EnableEV {
	try { 
			Set-CsUser -Identity $Global:selecteduser -EnterpriseVoiceEnabled $true
			[void][System.Windows.Forms.MessageBox]::Show("Enabled")
			Write-Host "Enabled" -ForegroundColor Yellow
		}
	catch { 
		[void][System.Windows.Forms.MessageBox]::Show("User could not be enabled for Enterprise Voice.")
		Write-Host "User could not be enabled for Enterprise Voice." -ForegroundColor Red
	 }	
}
#Enable Hosted Voicemail
function EnableHVM {
	try { 
			Set-CsUser -Identity $Global:selecteduser -HostedVoiceMail $true
			[void][System.Windows.Forms.MessageBox]::Show("Enabled.")
			Write-Host "Enabled" -ForegroundColor Yellow
		}
	catch { 
		[void][System.Windows.Forms.MessageBox]::Show("User could not be enabled for Hosted Voicemail.") 
		Write-Host "User could not be enabled for Hosted Voicemail." -ForegroundColor Red
	}
}
#Assign phone number (onprem line uri)
function AssignLineUri {
	try { 
			$Global:lineuri = $Global:Tenterlineuri.Text
			Set-CsUser -Identity $Global:selecteduser -OnPremLineURI $Global:lineuri -WhatIf 
			[void][System.Windows.Forms.MessageBox]::Show("$Global:lineuri assigned.")
		}
	catch { 
		[void][System.Windows.Forms.MessageBox]::Show("Could not assign phone number. `nPlease check $Global:lineuri if the value is correct. `nIt must be tel:+49..123.")	
		Write-Host "Could not assign phone number. Please check $Global:lineuri if the value is correct. It must be tel:+49..123." -ForegroundColor Red
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
		#Grant-CsTeamsCallingPolicy -PolicyName $usercp -Identity $Global:selecteduser -WhatIf 
		$Global:usercp = $Global:Cassigncp.Add_SelectedItem	
	}
	catch { 
		[void][System.Windows.Forms.MessageBox]::Show("Could not select calling policy.") 
	}		
}
#Assign calling policy
function AssignCP {
	try { 
			if ($Global:usercp -eq "Global"){
				Grant-CsTeamsCallingPolicy -Identity $Global:selecteduser -PolicyName $null
			}
			else {
				Grant-CsTeamsCallingPolicy -Identity $Global:selecteduser -PolicyName $Global:usercp
			}
			
		}
	catch { [void][System.Windows.Forms.MessageBox]::Show("Could not assign calling policy.") }		
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
	$Lenterprisevoice = New-Object System.Windows.Forms.Label
	$Tenterlineuri = New-Object System.Windows.Forms.TextBox
	$Ltermsofuse = New-Object System.Windows.Forms.Label
	$Lhostedvoicemail = New-Object System.Windows.Forms.Label
	$Lenterlineuri = New-Object System.Windows.Forms.Label
	$lenableteamsonly = New-Object System.Windows.Forms.Label
	$Bsetteamsonly = New-Object System.Windows.Forms.Button
	$Benableev = New-Object System.Windows.Forms.Button
	$Benablevm = New-Object System.Windows.Forms.Button
	$Bassignnumber = New-Object System.Windows.Forms.Button
	$Bassignvrp = New-Object System.Windows.Forms.Button
	$Bassigncp = New-Object System.Windows.Forms.Button
	$Lshouldbeonbydefault = New-Object System.Windows.Forms.Label
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
	$Lassignvrp.Location = New-Object System.Drawing.Point(12, 170)
	$Lassignvrp.Name = "Lassignvrp"
	$Lassignvrp.Size = New-Object System.Drawing.Size(132, 13)
	$Lassignvrp.TabIndex = 6
	$Lassignvrp.Text = "Online voice routing policy"

	# Cassignvrp
	$Global:Cassignvrp.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$Global:Cassignvrp.FormattingEnabled = $true
	$Global:Cassignvrp.Location = New-Object System.Drawing.Point(148, 170)
	$Global:Cassignvrp.Name = "Cassignvrp"
	$Global:Cassignvrp.Size = New-Object System.Drawing.Size(356, 21)
	$Global:Cassignvrp.TabIndex = 5
	#$Global:Cassignvrp.Add_Click( { ListOVRPs } )
	$Global:Cassignvrp.Add_SelectedIndexChanged( { SelectOVRP } )

	# Lassigncp
	$Lassigncp.AutoSize = $true
	$Lassigncp.Location = New-Object System.Drawing.Point(12, 197)
	$Lassigncp.Name = "Lassigncp"
	$Lassigncp.Size = New-Object System.Drawing.Size(101, 13)
	$Lassigncp.TabIndex = 8
	$Lassigncp.Text = "Calling policy"

	# Cassigncp
	$Global:Cassigncp.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$Global:Cassigncp.FormattingEnabled = $true
	$Global:Cassigncp.Location = New-Object System.Drawing.Point(148, 197)
	$Global:Cassigncp.Name = "Cassigncp"
	$Global:Cassigncp.Size = New-Object System.Drawing.Size(356, 21)
	$Global:Cassigncp.TabIndex = 7
	#$Global:Cassigncp.Add_Click( { ListCPs } )
	$Global:Cassigncp.Add_SelectedIndexChanged( { SelectCP } )
	
	# Lenterprisevoice
	$Lenterprisevoice.AutoSize = $true
	$Lenterprisevoice.Location = New-Object System.Drawing.Point(12, 92)
	$Lenterprisevoice.Name = "Lenterprisevoice"
	$Lenterprisevoice.Size = New-Object System.Drawing.Size(84, 13)
	$Lenterprisevoice.TabIndex = 9
	$Lenterprisevoice.Text = "Enterprise Voice"

	# Tenterlineuri
	$Tenterlineuri.Location = New-Object System.Drawing.Point(148, 144)
	$Tenterlineuri.Name = "Tenterlineuri"
	$Tenterlineuri.Size = New-Object System.Drawing.Size(356, 20)
	$Tenterlineuri.TabIndex = 10
	try {
		if (($currentlineuri -is $null) -or ($currentlineuri -like " ")){ $Tenterlineuri.Text = "e.g. tel:+49711987456123 or tel:+49711987456123;ext=123" }
		else { $Tenterlineuri.Text = "$currentlineuri" }
	}
	catch { $Tenterlineuri.Text = "e.g. tel:+49711987456123 or tel:+49711987456123;ext=123" }	

	# Ltermsofuse
	$Ltermsofuse.AutoSize = $true
	$Ltermsofuse.Font = New-Object System.Drawing.Font("Arial Narrow", 8.25,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point, 0)
	$Ltermsofuse.ForeColor = [System.Drawing.Color]::FromArgb(192,0,0)
	$Ltermsofuse.Location = New-Object System.Drawing.Point(145, 10)
	$Ltermsofuse.Name = "Ltermsofuse"
	$Ltermsofuse.Size = New-Object System.Drawing.Size(152, 15)
	$Ltermsofuse.TabIndex = 11
	$Ltermsofuse.Text = "Terms of use: Use on own risk. "
	
	# Lhostedvoicemail
	$Lhostedvoicemail.AutoSize = $true
	$Lhostedvoicemail.Location = New-Object System.Drawing.Point(12, 118)
	$Lhostedvoicemail.Name = "Lhostedvoicemail"
	$Lhostedvoicemail.Size = New-Object System.Drawing.Size(89, 13)
	$Lhostedvoicemail.TabIndex = 12
	$Lhostedvoicemail.Text = "Hosted Voicemail"
	
	# Lenterlineuri
	$Lenterlineuri.AutoSize = $true
	$Lenterlineuri.Location = New-Object System.Drawing.Point(12, 144)
	$Lenterlineuri.Name = "Lenterlineuri"
	$Lenterlineuri.Size = New-Object System.Drawing.Size(77, 13)
	$Lenterlineuri.TabIndex = 15
	$Lenterlineuri.Text = "Enter Line URI"

	# lenableteamsonly
	$lenableteamsonly.AutoSize = $true
	$lenableteamsonly.Location = New-Object System.Drawing.Point(12, 66)
	$lenableteamsonly.Name = "lenableteamsonly"
	$lenableteamsonly.Size = New-Object System.Drawing.Size(97, 13)
	$lenableteamsonly.TabIndex = 16
	$lenableteamsonly.Text = "Enable Teams-only"
	
	# Bsetteamsonly
	$Bsetteamsonly.AutoSize = $true
	$Bsetteamsonly.Location = New-Object System.Drawing.Point(148, 66)
	$Bsetteamsonly.Name = "Bsetteamsonly"
	$Bsetteamsonly.Size = New-Object System.Drawing.Size(100, 23)
	$Bsetteamsonly.TabIndex = 18
	$Bsetteamsonly.Text = "Set Teams-only"
	$Bsetteamsonly.UseVisualStyleBackColor = $true
	$Bsetteamsonly.Add_Click( { EnableTeamsOnly } )
	
	# Benableev
	$Benableev.Location = New-Object System.Drawing.Point(148, 92)
	$Benableev.Name = "Benableev"
	$Benableev.Size = New-Object System.Drawing.Size(100, 20)
	$Benableev.TabIndex = 19
	$Benableev.Text = "Enable EV"
	$Benableev.UseVisualStyleBackColor = $true
	$Benableev.Add_Click( { EnableEV } )
	
	# Benablevm
	$Benablevm.Location = New-Object System.Drawing.Point(148, 118)
	$Benablevm.Name = "Benablevm"
	$Benablevm.Size = New-Object System.Drawing.Size(100, 20)
	$Benablevm.TabIndex = 20
	$Benablevm.Text = "Enable VM"
	$Benablevm.UseVisualStyleBackColor = $true
	$Benablevm.Add_Click( { EnableHVM } )
	
	# Bassignnumber
	$Bassignnumber.Location = New-Object System.Drawing.Point(510, 144)
	$Bassignnumber.Name = "Bassignnumber"
	$Bassignnumber.Size = New-Object System.Drawing.Size(100, 20)
	$Bassignnumber.TabIndex = 21
	$Bassignnumber.Text = "Assign"
	$Bassignnumber.UseVisualStyleBackColor = $true
	$Bassignnumber.Add_Click( { AssignLineUri } )
	
	# Bassignvrp
	$Bassignvrp.Location = New-Object System.Drawing.Point(510, 170)
	$Bassignvrp.Name = "Bassignvrp"
	$Bassignvrp.Size = New-Object System.Drawing.Size(100, 20)
	$Bassignvrp.TabIndex = 22
	$Bassignvrp.Text = "Assign"
	$Bassignvrp.UseVisualStyleBackColor = $true
	$Bassignvrp.Add_Click( { AssignOVRP } )
	
	# Bassigncp
	$Bassigncp.Location = New-Object System.Drawing.Point(510, 197)
	$Bassigncp.Name = "Bassigncp"
	$Bassigncp.Size = New-Object System.Drawing.Size(100, 20)
	$Bassigncp.TabIndex = 23
	$Bassigncp.Text = "Assign"
	$Bassigncp.UseVisualStyleBackColor = $true
	$Bassigncp.Add_Click( { AssignCP } )
	
	# Lshouldbeonbydefault
	$Lshouldbeonbydefault.AutoSize = $true
	$Lshouldbeonbydefault.Font = New-Object System.Drawing.Font("Arial Narrow", 8.25,[System.Drawing.FontStyle]::Regular,[System.Drawing.GraphicsUnit]::Point, 0)
	$Lshouldbeonbydefault.ForeColor = [System.Drawing.Color]::Black
	$Lshouldbeonbydefault.Location = New-Object System.Drawing.Point(254, 121)
	$Lshouldbeonbydefault.Name = "Lshouldbeonbydefault"
	$Lshouldbeonbydefault.Size = New-Object System.Drawing.Size(107, 15)
	$Lshouldbeonbydefault.TabIndex = 24
	$Lshouldbeonbydefault.Text = "Should be on by default."
	
	# Lreleasenotes
	$Lreleasenotes.AutoSize = $true
	$Lreleasenotes.Font = New-Object System.Drawing.Font("Arial Narrow", 8.25,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point, 0)
	$Lreleasenotes.ForeColor = [System.Drawing.Color]::Green
	$Lreleasenotes.Location = New-Object System.Drawing.Point(12, 231)
	$Lreleasenotes.Name = "Lreleasenotes"
	$Lreleasenotes.Size = New-Object System.Drawing.Size(155, 15)
	$Lreleasenotes.TabIndex = 25
	$Lreleasenotes.Text = "V 0.2 Erik Kleefeldt May 2021"
	
	# LLerik365blog
	$LLerik365blog.AutoSize = $true
	$LLerik365blog.Location = New-Object System.Drawing.Point(507, 233)
	$LLerik365blog.Name = "LLerik365blog"
	$LLerik365blog.Size = New-Object System.Drawing.Size(101, 13)
	$LLerik365blog.TabIndex = 26
	$LLerik365blog.TabStop = $true
	$LLerik365blog.Text = "https://erik365.blog"
	$LLerik365blog.Add_Click( { OpenBlogOnClick } )
	
	# FMain
	$FMain.BackgroundImageLayout = [System.Windows.Forms.ImageLayout]::None
	$FMain.ClientSize = New-Object System.Drawing.Size(620, 250)
	$FMain.Controls.Add($LLerik365blog)
	$FMain.Controls.Add($Lreleasenotes)
	$FMain.Controls.Add($Lshouldbeonbydefault)
	$FMain.Controls.Add($Bassigncp)
	$FMain.Controls.Add($Bassignvrp)
	$FMain.Controls.Add($Bassignnumber)
	$FMain.Controls.Add($Benablevm)
	$FMain.Controls.Add($Benableev)
	$FMain.Controls.Add($Bsetteamsonly)
	$FMain.Controls.Add($lenableteamsonly)
	$FMain.Controls.Add($Lenterlineuri)
	$FMain.Controls.Add($Lhostedvoicemail)
	$FMain.Controls.Add($Tenterlineuri)
	$FMain.Controls.Add($Lenterprisevoice)
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
	$FMain.Text = "Erik365Online - Teams Direct Routing User Number Assigner"
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