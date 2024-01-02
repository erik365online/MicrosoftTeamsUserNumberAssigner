<#
.SYNOPSIS
Teams Direct Routing User Number Assigner (TDR-UNA)

.DESCRIPTION
	Use on your own risk. The script opens a graphical user interface (GUI) to simplify a few basic enablement tasks. 
	It's called the Teams Direct Routing User Number Assigner (TDR-UNA) and can be used to enable a single Teams User for Teams Direct Routing.
	Use on your own risk.
  Features V0.4
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

  Bugs, issues and limitations V0.4
	- Not checking for assigned licsense sku or Assigned Plan for a listed or selected user
 	- No refresh of users after a change to a user was applied is implemented (disconnect, close, open, connect required)
	- Resource accounts are listed
	- Changing resource account numbers is not implemented/supported/tested
	- Deleting resource account phone numbers in not implemented/supported/tested
	- No code-signed script
	- No certificate-based authentication (maybe in a future release)
	- No application-based access token authentication (maybe in a future release)

.EXAMPLE
C:\PS> .\TDR-UNA.ps1

.NOTES
Version: 0.4
Author: Erik Kleefeldt
08.01.2021 Initial script development
31.02.2021 Script development
21.03.2021 Check Teams Module V2 Adjustments
24.05.2021 Minor Adjustments
19.04.2021 Adjustments to run with Teams PowerShell Module Version 4.2.0
29.12.2023 Optimized and adjustments to run with Teams PowerShell Module Version 5.8.0

.LINK
https://www.erik365.blog
#>

#Loading external assemblies
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    try {
        Import-Module MicrosoftTeams	
    }
    catch {
        Write-Host "There's no Microsoft Teams Module installed or it could not be imported." -ForegroundColor Red
        throw "There's no Microsoft Teams Module installed or it could not be imported. `n Please open PowerShell as an admin an run the Install-Module MicrosoftTeams cmdlet."
    }

#Variables area (start declaration)	
	$connected = "no"
	$userslistedonce = "no"
	$ovrpslistedonce = "no"
	$cpslistedonce = "no"	
	$url = "https://microsoft.com/devicelogin"

#Functions
function FuKeepformok {	
	# Position the form on the screen
	$FWindow.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
}
#Close app on X
    function FuCloseForm{ 
        Write-Host "Closing app ..." -ForegroundColor Yellow	        
        ($_).Cancel= $False
    }
#Close app button
    function FuCloseOnClick {	
        Write-Host "App is being closed ..." -ForegroundColor Yellow
        $FWindow.Close()
    }
#Open Link on click in web browser
    function FuOpenBlogLink {
        [Diagnostics.Process]::Start("https://www.erik365.blog","arguments")	
    }
#Connect Teams
function ConnectTeamsOnClick {	
	try {			
		if ($connected -ne "connected"){			
			#Connect Teams
			Write-Host "Connecting ..." -ForegroundColor Yellow									
			Write-Host "Please use the shown code from your PowerShell terminal to login via browser ..." -ForegroundColor Yellow
			# Open the URL in the default web browser
			Start-Process $url
			Connect-MicrosoftTeams -UseDeviceAuthentication

			$connected = "connected"
			[void][System.Windows.Forms.MessageBox]::Show("Connected to Teams")	
			Write-Host "Connected" -ForegroundColor Yellow			
			Write-Host "Loading users and policies ..." -ForegroundColor Yellow
			
			#Directly start to load users and policies after connect is done			
			ListUsers
			ListOVRPs
			ListCPs	
			Write-Host "Loading completed" -ForegroundColor Yellow
		}
		else{			
			[void][System.Windows.Forms.MessageBox]::Show("Already connected")
			Write-Host "Already Connected." -ForegroundColor Yellow
		}
	}
	catch {	
		$connected = "no"		
		[void][System.Windows.Forms.MessageBox]::Show("Could not connect to Teams.`n Please ensure connectivity and Teams Module is installed.")
		Write-Host "Could connect to Teams. Please ensure Teams Module is installed." -ForegroundColor Red
	}
}
#Referesh Teams contents / reload users and policies
function RefreshTeamsOnClick {	
	try {			
		if ($connected -ne "connected"){
			$connected = "connected"			
			Write-Host "Connected" -ForegroundColor Yellow			
			Write-Host "Loading users and policies ..." -ForegroundColor Yellow
			
			#Directly start to load users and policies after connect is done			
			ListUsers
			ListOVRPs
			ListCPs	
			Write-Host "Loading completed" -ForegroundColor Yellow
		}
		else{			
			[void][System.Windows.Forms.MessageBox]::Show("Already connected")
			Write-Host "Already Connected." -ForegroundColor Yellow
		}
	}
	catch {	
		$connected = "no"		
		[void][System.Windows.Forms.MessageBox]::Show("Could not refresh contents")
		Write-Host "Could refresh contents" -ForegroundColor Red
	}
}
#Disconnect MS Teams
function DisconnectTeamsOnClick {	
	try {		
		if ($connected -eq "connected"){			
			Write-Host "Disconnecting Teams" -ForegroundColor Yellow
			Disconnect-MicrosoftTeams -Verbose	
			[void][System.Windows.Forms.MessageBox]::Show("Disconnected")
			Write-Host "Disconnected" -ForegroundColor Yellow
			$connected = "no"						
		}
		else {
			[void][System.Windows.Forms.MessageBox]::Show("Not connected")
		}		
	}
	catch {
		if ($connected -eq "connected"){$connected = "no"}
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
        if ($userslistedonce -ne "yes"){	
            try {
                $userslistedonce = "yes"		
                $Cselectuser.Items.Clear()
                Write-Host "Cleaning user list ..."	-ForegroundColor Yellow			
                Write-Host "Loading user list ..."	-ForegroundColor Yellow
                Write-host "Please wait, this can take some time depending on how many users you host on Teams ..." -ForegroundColor Yellow
                #get users
                $allusers = Get-CsOnlineUser
                #count users
                $usercounter = ($allusers).count
                $ipb1 = 0 #progresscounter
                #populate dropdown list with upns and display progress bar			
                $allusers | Sort-Object UserPrincipalName | ForEach-Object {
                    #assuming that upn=primary smtp=primary sip address 			
                    [void] $Cselectuser.Items.Add($_.UserPrincipalName)				
                    Write-Progress -Activity "Loading in progress ..." -Status "Progress" -PercentComplete ((($ipb1++) / $usercounter) * 100)
                    }
                    #remove progress bar if done
                    #Write-Progress -Activity "Loading in progress ..." -Status "Ready" -Completed
                    #set variable to no re-initialize the drop down by Add_Click(...) again								
            }
            catch {
                [void][System.Windows.Forms.MessageBox]::Show("Could not get Team users. `nPlease check connectivity and retry.")
                Write-Host "Could not get Team users. Please check connectivity and retry." -ForegroundColor Red
                $userslistedonce = "no"			
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
		$selecteduser = $Cselectuser.SelectedItem
		Write-Host $selecteduser -ForegroundColor Yellow

		$currentuser = (Get-CsOnlineUser "$selecteduser")		
		$currentuser | Format-List UserPrincipalName,LineUri,OnlineVoiceRoutingPolicy,TeamsCallingPolicy,TenantDialPlan

		#Collect data into variables
		$currentupn = ($currentuser).UserPrincipalName
		$currentsip = ($currentuser).SipAddress
		$currentlineuri = ($currentuser).LineUri
		$currentovrp = ($currentuser).OnlineVoiceRoutingPolicy	
		$currentcp = ($currentuser).TeamsCallingPolicy		
		if ($null -eq $currentcp){ 
			$currentcp = "Global" 
		}
		else { 
			#Do nothing 
		}

		#Build nice output object
		$currentuserobj = New-Object -TypeName psobject
		$currentuserobj | Add-Member -MemberType NoteProperty -Name "UPN" -Value "$currentupn"
		$currentuserobj | Add-Member -MemberType NoteProperty -Name "SIP" -Value "$currentsip"
		$currentuserobj | Add-Member -MemberType NoteProperty -Name "LineUri" -Value "$currentlineuri"		
		$currentuserobj | Add-Member -MemberType NoteProperty -Name "OnlineVoiceRoutingPolicy" -Value "$currentovrp"
		$currentuserobj | Add-Member -MemberType NoteProperty -Name "CallingPolicy" -Value "$currentcp"		
		#Show custom object
		$currentuserobj.PSObject.Properties | ForEach-Object {
			$name = $_.Name 
			$value = $_.value
			Write-Host "$name = $value" -ForegroundColor Yellow
		} 
	}
	catch { 
		[void][System.Windows.Forms.MessageBox]::Show("No user could be selected. Please select a user.") 
		Write-Host "No user could be selected. Please select a user." -ForegroundColor Red
	}
}

#Assign phone number
function AssignLineUri {
	try { 
		$lineuri = $Tenterlineuri.Text				
		Set-CsPhoneNumberAssignment -Identity "$selecteduser" -PhoneNumber "$lineuri" -PhoneNumberType DirectRouting
		#Noted and reservered for future releases
		#Set-CsPhoneNumberAssignment -Identity "$selecteduser" -PhoneNumber "$lineuri" -PhoneNumberType CallingPlan
		#Set-CsPhoneNumberAssignment -Identity "$selecteduser" -PhoneNumber "$lineuri" -PhoneNumberType OperatorConnect
		#Set-CsPhoneNumberAssignment -Identity "$selecteduser" -PhoneNumber "$lineuri" -PhoneNumberType OCMobile		
		
		[void][System.Windows.Forms.MessageBox]::Show("$lineuri assigned to $selecteduser.")
		Write-Host "$lineuri assigned to $selecteduser." -ForegroundColor Yellow
		}
	catch { 
		[void][System.Windows.Forms.MessageBox]::Show("Could not assign phone number. `nPlease check´n $lineuri ´nif the value is correct. `nIt must be tel:+49..123.")	
		Write-Host "Could not assign phone number. Please check $lineuri if the value is correct. It must be +49..123" -ForegroundColor Red
	}
}
#Release phone number (DIRECT ROUTING)
function ReleaseNumber {
	try { 
		Remove-CsPhoneNumberAssignment -Identity "$selecteduser" -RemoveAll 
		Write-Host "Phone number for $selecteduser was removed." -ForegroundColor Yellow
		[void][System.Windows.Forms.MessageBox]::Show("$selecteduser phone number removed and EV disabled")
		}
	catch { 
		[void][System.Windows.Forms.MessageBox]::Show("Could not remove phone number for $selecteduser")	
		Write-Host "Could not remove phone number for $selecteduser" -ForegroundColor Red
	}
}
#List online voice routing policis
function ListOVRPs {
	if ($ovrpslistedonce -ne "yes"){
		$ovrpslistedonce = "yes"
		$Cassignvrp.Items.Clear()
		Write-Host "Loading online voice routing policies ..." -ForegroundColor Yellow
		try {
			$allovrps = Get-CsOnlineVoiceRoutingPolicy
			$ovrpscounter = ($allovrps).count
			$ipb2 = 0 #progresscounter
			$allovrps | ForEach-Object { 
				[void] $Cassignvrp.Items.Add($_.Identity) 
				Write-Progress -Activity "Loading in online voice routing policies ..." -Status "Progress" -PercentComplete ((($ipb2++) / $ovrpscounter) * 100)
			}		
			Write-Progress -Activity "Loading in online voice routing policies ..." -Status "Ready" -Completed			
			#return $ovrpslistedonce						
		}
		catch { 
			[void][System.Windows.Forms.MessageBox]::Show("Could not find any online voice routing policy") 
			Write-Host "Could not find any online voice routing policy" -ForegroundColor Red
			$ovrpslistedonce = "no"
		}				
	}
	else {
		#Do nothing
	}
}
#Select online voice routing policy
function SelectOVRP {
		try { 
			$userovrp = $Cassignvrp.SelectedItem
			Write-Host "Selected online voice routing policy: $userovrp" -ForegroundColor Yellow			
		}
		catch { 
			[void][System.Windows.Forms.MessageBox]::Show("Could not select online voice routing policy") 
			Write-Host "Could not select online voice routing policy $userovrp." -ForegroundColor Red
		}			
}
#Assign online voice routing policy
function AssignOVRP {
	try { 
		if($userovrp -eq "Global"){
			Grant-CsOnlineVoiceRoutingPolicy -Identity $selecteduser -PolicyName $null
			Write-Host "Assign global OVRP to $selecteduser" -ForegroundColor Yellow
		}
		else {
			Grant-CsOnlineVoiceRoutingPolicy -Identity $selecteduser -PolicyName $userovrp	
			Write-Host "Assign $userovrp to $selecteduser" -ForegroundColor Yellow
		}		
	}
	catch { 
		[void][System.Windows.Forms.MessageBox]::Show("Could not assign online voice routing policy.") 
		Write-Host "Could not assign online voice routing policy to $selecteduser." -ForegroundColor Red
	}			
}
#List calling policis
function ListCPs {
	if ($cpslistedonce -ne "yes"){
		Write-Host "Loading calling policies..." -ForegroundColor Yellow
		try {
			$cpslistedonce = "yes"
			$allcallingpolicies = Get-CsTeamsCallingPolicy
			$cpscounter = ($allcallingpolicies).count
			$ipb3 = 0 #progresscounter
			$allcallingpolicies | ForEach-Object {
				[void] $Cassigncp.Items.Add($_.Identity) 
				Write-Progress -Activity "Loading in calling policies ..." -Status "Progress" -PercentComplete ((($ipb3++) / $cpscounter) * 100)
			}
			Write-Progress -Activity "Loading in calling policies ..." -Status "Ready" -Completed	
		}
		catch { 
			[void][System.Windows.Forms.MessageBox]::Show("Could not find any calling policy.") 
			Write-Host "Could not find any calling policy" -ForegroundColor Red
			$cpslistedonce = "no"
		}
	}
	else {
		#Do nothing
	}
}
#Select calling policy
function SelectCP {
	try {  
		$usercp = $Cassigncp.SelectedItem	
		Write-Host "Selected calling policy: $usercp" -ForegroundColor Yellow	
	}
	catch { 
		[void][System.Windows.Forms.MessageBox]::Show("Could not select calling policy.") 
		Write-Host "Could not select calling policy $usercp." -ForegroundColor Red
	}		
}
#Assign calling policy
function AssignCP {
	try { 
			if ($usercp -eq "Global"){
				Grant-CsTeamsCallingPolicy -Identity $selecteduser -PolicyName $null
				Write-Host "Assign global calling policy to $selecteduser" -ForegroundColor Yellow
			}
			else {
				Grant-CsTeamsCallingPolicy -Identity $selecteduser -PolicyName $usercp
				Write-Host "Assign calling policy $usercp to $selecteduser" -ForegroundColor Yellow
			}
			
		}
	catch { 
		[void][System.Windows.Forms.MessageBox]::Show("Could not assign calling policy $usercp to $selecteduser.")
		Write-Host "Could not assign calling policy $usercp to $selecteduser" -ForegroundColor Yellow 
	}		
}

#Export phone numbers to CSV
function ExportPhoneNumbers {
	#Selected storage location
	write-host "Select storage location for CSV file." -ForegroundColor Yellow
	$saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveFileDialog.Filter = "CSV files (*.csv)|*.csv"
    $saveFileDialog.Title = "Save CSV File"
    $saveFileDialog.ShowDialog()
	$filepath = $saveFileDialog.FileName 
	write-host "Storage location for CSV file: $filepath" -ForegroundColor Yellow

    if ($saveFileDialog.FileName -ne "") {
		#export all users to csv
		Write-Host "Exporting all users to CSV file ..." -ForegroundColor Yellow
		$index = 0
        $totalUsers = $allusers.Count
		$allusers | ForEach-Object {
			$index++
			$csvline = $_.UserPrincipalName + ";" + $_.SipAddress + ";" + $_.LineUri + ";" + $_.OnlineVoiceRoutingPolicy + ";" + $_.TeamsCallingPolicy
			$csv.Add($csvline)
			# Update the progress bar
            Write-Progress -Activity "Exporting users to CSV" -Status "$index of $totalUsers users exported" -PercentComplete ($index / $totalUsers * 100)
		}  
		$csv | Export-Csv -Path $saveFileDialog.FileName -Append -NoTypeInformation -Encoding UTF8	
		Write-Host "Exporting all users to CSV file completed." -ForegroundColor Yellow
    } else {
        Write-Host "No file path was specified." -ForegroundColor Red
		[void][System.Windows.Forms.MessageBox]::Show("No file path was specified.")
    }
}

#Form assembly area

function GenerateForm {
	#Form assembly
	$FWindow = New-Object System.Windows.Forms.Form
	$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState

	$Bconnectteams = New-Object System.Windows.Forms.Button
	$Brefresh = New-Object System.Windows.Forms.Button
	$Bdisconnectteams = New-Object System.Windows.Forms.Button
	$Bclose = New-Object System.Windows.Forms.Button
	$Cselectuser = New-Object System.Windows.Forms.ComboBox
	$Lselectuser = New-Object System.Windows.Forms.Label
	$Lassignvrp = New-Object System.Windows.Forms.Label
	$Cassignvrp = New-Object System.Windows.Forms.ComboBox
	$Lassigncp = New-Object System.Windows.Forms.Label
	$Cassigncp = New-Object System.Windows.Forms.ComboBox	
	$Tenterlineuri = New-Object System.Windows.Forms.TextBox
	$Ltermsofuse = New-Object System.Windows.Forms.Label	
	$Lenterlineuri = New-Object System.Windows.Forms.Label
	$Breleasenumber = New-Object System.Windows.Forms.Button
	$Bexport = New-Object System.Windows.Forms.Button
	$Bassignnumber = New-Object System.Windows.Forms.Button
	$Bassignvrp = New-Object System.Windows.Forms.Button
	$Bassigncp = New-Object System.Windows.Forms.Button
	$Lreleasenumber = New-Object System.Windows.Forms.Label
	$Lexport = New-Object System.Windows.Forms.Label
	$Lreleasenotes = New-Object System.Windows.Forms.Label
	$LLerik365blog = New-Object System.Windows.Forms.LinkLabel	
	
	#Formatting	
	$fontboldtext = New-Object System.Drawing.Font("Arial", 9,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point, 0)	

	# Bconnectteams	
	$Bconnectteams.Location = New-Object System.Drawing.Point(10, 10)
	$Bconnectteams.Name = "Bconnectteams"
	$Bconnectteams.Size = New-Object System.Drawing.Size(104, 20)
	$Bconnectteams.TabIndex = 0
	$Bconnectteams.Text = "Connect Teams"
	$Bconnectteams.UseVisualStyleBackColor = $true
	$Bconnectteams.Add_Click( { ConnectTeamsOnClick } )

	# Brefresh
	$Brefresh.Location = New-Object System.Drawing.Point(124, 10)
	$Brefresh.Name = "Brefresh"
	$Brefresh.Size = New-Object System.Drawing.Size(104, 20)
	$Brefresh.TabIndex = 0
	$Brefresh.Text = "Refresh"
	$Brefresh.UseVisualStyleBackColor = $true
	$Brefresh.Add_Click( { RefreshTeamsOnClick } )

	# Bdisconnectteams
	$Bdisconnectteams.Location = New-Object System.Drawing.Point(390, 10)
	$Bdisconnectteams.Name = "Bdisconnectteams"
	$Bdisconnectteams.Size = New-Object System.Drawing.Size(108, 20)
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
	$Bclose.Add_Click( { FuCloseOnClick } )	

	# Cselectuser
	$Cselectuser.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$Cselectuser.FormattingEnabled = $true
	$Cselectuser.Location = New-Object System.Drawing.Point(148, 39)
	$Cselectuser.MaxDropDownItems = 10
	$Cselectuser.Name = "Cselectuser"
	$Cselectuser.Size = New-Object System.Drawing.Size(356, 21)
	$Cselectuser.Sorted = $true
	$Cselectuser.TabIndex = 3
	#$Cselectuser.Add_Click( { ListUsers } ) #reinitializes, readds etc.
	#ListUsers
	$Cselectuser.Add_SelectedIndexChanged( { SelectUser } )

	# Lselectuser
	$Lselectuser.AutoSize = $true
	$Lselectuser.Location = New-Object System.Drawing.Point(12, 42)
	$Lselectuser.Name = "Lselectuser"
	$Lselectuser.Size = New-Object System.Drawing.Size(60, 13)
	$Lselectuser.TabIndex = 4
	$Lselectuser.Text = "User"
	$Lselectuser.Font = $fontboldtext
	
	# Lassignvrp
	$Lassignvrp.AutoSize = $true
	$Lassignvrp.Location = New-Object System.Drawing.Point(12, 84)
	$Lassignvrp.Name = "Lassignvrp"
	$Lassignvrp.Size = New-Object System.Drawing.Size(132, 13)
	$Lassignvrp.TabIndex = 6
	$Lassignvrp.Text = "Voice routing policy"
	$Lassignvrp.Font = $fontboldtext

	# Cassignvrp
	$Cassignvrp.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$Cassignvrp.FormattingEnabled = $true
	$Cassignvrp.Location = New-Object System.Drawing.Point(148, 84)
	$Cassignvrp.Name = "Cassignvrp"
	$Cassignvrp.Size = New-Object System.Drawing.Size(356, 21)
	$Cassignvrp.IntegralHeight = $true
	$Cassignvrp.MaxDropDownItems = 15
	$Cassignvrp.TabIndex = 5
	#$Cassignvrp.Add_Click( { ListOVRPs } )
	$Cassignvrp.Add_SelectedIndexChanged( { SelectOVRP } )

	# Lassigncp
	$Lassigncp.AutoSize = $true
	$Lassigncp.Location = New-Object System.Drawing.Point(12, 105)
	$Lassigncp.Name = "Lassigncp"
	$Lassigncp.Size = New-Object System.Drawing.Size(101, 13)
	$Lassigncp.TabIndex = 8
	$Lassigncp.Text = "Calling policy"
	$Lassigncp.Font = $fontboldtext

	# Cassigncp
	$Cassigncp.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$Cassigncp.FormattingEnabled = $true
	$Cassigncp.Location = New-Object System.Drawing.Point(148, 105)
	$Cassigncp.Name = "Cassigncp"	
	$Cassigncp.Size = New-Object System.Drawing.Size(356, 21)	
	$Cassigncp.IntegralHeight = $true
	$Cassigncp.MaxDropDownItems = 15	
	$Cassigncp.TabIndex = 7
	#$Cassigncp.Add_Click( { ListCPs } )
	$Cassigncp.Add_SelectedIndexChanged( { SelectCP } )
	
	# Tenterlineuri
	$Tenterlineuri.Location = New-Object System.Drawing.Point(148, 63)
	$Tenterlineuri.Name = "Tenterlineuri"
	$Tenterlineuri.Size = New-Object System.Drawing.Size(356, 20)
	$Tenterlineuri.TabIndex = 10
	try {
		if (($null -eq $currentlineuri) -or ($currentlineuri -eq " ")){ $Tenterlineuri.Text = "e.g. +49711987456123" }
		else { $Tenterlineuri.Text = "$currentlineuri" }
	}
	catch { $Tenterlineuri.Text = "e.g. +49711987456123" }	

	# Lenterlineuri
	$Lenterlineuri.AutoSize = $true
	$Lenterlineuri.Location = New-Object System.Drawing.Point(12, 63)
	$Lenterlineuri.Name = "Lenterlineuri"
	$Lenterlineuri.Size = New-Object System.Drawing.Size(77, 13)
	$Lenterlineuri.TabIndex = 15
	$Lenterlineuri.Text = "Add number (LineUri)"
	$lenterlineuri.Font = $fontboldtext

	# Lreleasenumber
	$Lreleasenumber.AutoSize = $true
	$Lreleasenumber.Location = New-Object System.Drawing.Point(12, 126)
	$Lreleasenumber.Name = "Lreleasenumber"
	$Lreleasenumber.Size = New-Object System.Drawing.Size(100, 13)
	$Lreleasenumber.TabIndex = 15
	$Lreleasenumber.Text = "Remove number"
	$Lreleasenumber.Font = $fontboldtext

	# Lexport
	$Lexport.AutoSize = $true
	$Lexport.Location = New-Object System.Drawing.Point(12, 147)
	$Lexport.Name = "Lexport"
	$Lexport.Size = New-Object System.Drawing.Size(100, 13)
	$Lexport.TabIndex = 28
	$Lexport.Text = "Export numbers (CSV)"
	$Lexport.Font = $fontboldtext

	# Breleasenumber
	$Breleasenumber.Location = New-Object System.Drawing.Point(148, 126)	
	$Breleasenumber.Name = "Breleasenumber"
	$Breleasenumber.Size = New-Object System.Drawing.Size(130, 20)
	$Breleasenumber.TabIndex = 19
	$Breleasenumber.Text = "Removal LineUri"
	$Breleasenumber.UseVisualStyleBackColor = $true
	#$Breleasenumber.Font = $buttonboldtext
	$Breleasenumber.Add_Click( { ReleaseNumber } )

	# Bexport
	$Bexport.Location = New-Object System.Drawing.Point(148, 147)
	$Bexport.Name = "Bexport"
	$Bexport.Size = New-Object System.Drawing.Size(130, 20)
	$Bexport.TabIndex = 27
	$Bexport.Text = "Start export"
	$Bexport.UseVisualStyleBackColor = $true
	$Bexport.Add_Click( { ExportPhoneNumbers } )

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

	# Ltermsofuse
	$Ltermsofuse.AutoSize = $true
	$Ltermsofuse.Font = New-Object System.Drawing.Font("Arial", 9,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point, 3)
	$Ltermsofuse.ForeColor = [System.Drawing.Color]::FromArgb(255,0,0)
	$Ltermsofuse.Location = New-Object System.Drawing.Point(12, 188)
	$Ltermsofuse.Name = "Ltermsofuse"
	$Ltermsofuse.Size = New-Object System.Drawing.Size(155, 15)
	$Ltermsofuse.TabIndex = 11
	$Ltermsofuse.Text = "Terms of use: Use on your own risk!"

	# Lreleasenotes
	$Lreleasenotes.AutoSize = $true
	$Lreleasenotes.Font = New-Object System.Drawing.Font("Arial", 9,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point, 0)
	$Lreleasenotes.ForeColor = [System.Drawing.Color]::Green
	$Lreleasenotes.Location = New-Object System.Drawing.Point(12, 208)
	$Lreleasenotes.Name = "Lreleasenotes"
	$Lreleasenotes.Size = New-Object System.Drawing.Size(155, 15)
	$Lreleasenotes.TabIndex = 25
	$Lreleasenotes.Text = "V 0.4 Erik Kleefeldt December 2023"

	# LLerik365blog
	$LLerik365blog.AutoSize = $true
	$LLerik365blog.Font = New-Object System.Drawing.Font("Arial", 9,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point, 0)
	$LLerik365blog.Location = New-Object System.Drawing.Point(480, 208)
	$LLerik365blog.Name = "LLerik365blog"
	$LLerik365blog.Size = New-Object System.Drawing.Size(155, 13)
	$LLerik365blog.TabIndex = 26
	$LLerik365blog.TabStop = $true
	$LLerik365blog.Text = "Visit www.erik365.blog"
	$LLerik365blog.Add_Click( { FuOpenBlogLink } )

	# FWindow
	$FWindow.BackgroundImageLayout = [System.Windows.Forms.ImageLayout]::None
	$FWindow.ClientSize = New-Object System.Drawing.Size(620, 229)
	$FWindow.AutoScaleMode = 3
	$FWindow.AutoSize = $true		
	$FWindow.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle	
	$FWindow.Name = "FWindow"
	$FWindow.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
	$FWindow.Text = "erik365.blog - Teams Direct Routing User Number Assigner V0.4"
	#$FWindow.Topmost = $true
	$FWindow.Controls.Add($LLerik365blog)
	$FWindow.Controls.Add($Lreleasenotes)	
	$FWindow.Controls.Add($Bassigncp)
	$FWindow.Controls.Add($Bassignvrp)
	$FWindow.Controls.Add($Bassignnumber)
	$FWindow.Controls.Add($Lreleasenumber)
	$FWindow.Controls.Add($Lexport)
	$FWindow.Controls.Add($Breleasenumber)	
	$FWindow.Controls.Add($Bexport)	
	$FWindow.Controls.Add($Lenterlineuri)	
	$FWindow.Controls.Add($Tenterlineuri)	
	$FWindow.Controls.Add($Lassigncp)
	$FWindow.Controls.Add($Cassigncp)
	$FWindow.Controls.Add($Lassignvrp)
	$FWindow.Controls.Add($Cassignvrp)
	$FWindow.Controls.Add($Lselectuser)
	$FWindow.Controls.Add($Cselectuser)
	$FWindow.Controls.Add($Bclose)
	$FWindow.Controls.Add($Bdisconnectteams)
	$FWindow.Controls.Add($Ltermsofuse)
	$FWindow.Controls.Add($Bconnectteams)	
	$FWindow.Controls.Add($Brefresh)	
	$FWindow.Add_FormClosing( { FuCloseForm } )
	$FWindow.Add_Shown({$FWindow.Activate()})
	
	#Initial form state		
	$FWindow.WindowState = $InitialFormWindowState
	#Intiate OnLoad event to correct the initial state of the form
	$FWindow.add_Load( { FuKeepformok } )

	#$Result=$FWindow.ShowDialog()
	[void]$FWindow.ShowDialog()

	# Release the Form
	$FWindow.Dispose()
}

#Call the form function
GenerateForm
