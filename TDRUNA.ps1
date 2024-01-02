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
02.01.2024 Optimized and adjustments to run with Teams PowerShell Module Version 5.8.0

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
	$Global:connected = "no"
	$Global:userslistedonce = "no"
	$Global:ovrpslistedonce = "no"
	$Global:cpslistedonce = "no"	
	$Global:url = "https://microsoft.com/devicelogin"

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
		if ($Global:connected -ne "connected"){			
			#Connect Teams
			Write-Host "Connecting ..." -ForegroundColor Yellow									
			Write-Host "Please use the shown code from your PowerShell terminal to login via browser ..." -ForegroundColor Yellow
			# Open the URL in the default web browser
			Start-Process $Global:url
			Connect-MicrosoftTeams -UseDeviceAuthentication

			$Global:connected = "connected"
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
		$Global:connected = "no"		
		[void][System.Windows.Forms.MessageBox]::Show("Could not connect to Teams.`n Please ensure connectivity and Teams Module is installed.")
		Write-Host "Could connect to Teams. Please ensure Teams Module is installed." -ForegroundColor Red
	}
}
#Referesh Teams contents / reload users and policies
function RefreshTeamsOnClick {	
	try {			
		if ($Global:connected -ne "connected"){
			$Global:connected = "connected"			
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
		$Global:connected = "no"		
		[void][System.Windows.Forms.MessageBox]::Show("Could not refresh contents")
		Write-Host "Could refresh contents" -ForegroundColor Red
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
                Write-host "Please wait, this can take some time depending on how many users you host on Teams ..." -ForegroundColor Yellow
                #get users
                $Global:allusers = Get-CsOnlineUser
                #count users
                $usercounter = ($Global:allusers).count
                $ipb1 = 0 #progresscounter
                #populate dropdown list with upns and display progress bar			
                $Global:allusers | Sort-Object UserPrincipalName | ForEach-Object {
                    #assuming that upn=primary smtp=primary sip address 			
                    [void] $Global:Cselectuser.Items.Add($_.UserPrincipalName)				
                    Write-Progress -Activity "Loading in progress ..." -Status "Progress" -PercentComplete ((($ipb1++) / $usercounter) * 100)
                    }
                    #remove progress bar if done
                    #Write-Progress -Activity "Loading in progress ..." -Status "Ready" -Completed
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
		$Global:currentuser | Format-List UserPrincipalName,LineUri,OnlineVoiceRoutingPolicy,TeamsCallingPolicy,TenantDialPlan

		#Collect data into variables
		$Global:currentupn = ($Global:currentuser).UserPrincipalName
		$Global:currentsip = ($Global:currentuser).SipAddress
		$Global:currentlineuri = ($Global:currentuser).LineUri
		$Global:currentovrp = ($Global:currentuser).OnlineVoiceRoutingPolicy	
		$Global:currentcp = ($Global:currentuser).TeamsCallingPolicy		
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
		$Global:currentuserobj | Add-Member -MemberType NoteProperty -Name "OnlineVoiceRoutingPolicy" -Value "$Global:currentovrp"
		$Global:currentuserobj | Add-Member -MemberType NoteProperty -Name "CallingPolicy" -Value "$Global:currentcp"

		#Show custom object
		$Global:currentuserobj.PSObject.Properties | ForEach-Object {
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
		$Global:lineuri = $Tenterlineuri.Text				
		Set-CsPhoneNumberAssignment -Identity "$Global:selecteduser" -PhoneNumber "$Global:lineuri" -PhoneNumberType DirectRouting
		#Noted and reservered for future releases
		#Set-CsPhoneNumberAssignment -Identity "$Global:selecteduser" -PhoneNumber "$Global:lineuri" -PhoneNumberType CallingPlan
		#Set-CsPhoneNumberAssignment -Identity "$Global:selecteduser" -PhoneNumber "$Global:lineuri" -PhoneNumberType OperatorConnect
		#Set-CsPhoneNumberAssignment -Identity "$Global:selecteduser" -PhoneNumber "$Global:lineuri" -PhoneNumberType OCMobile		
		
		[void][System.Windows.Forms.MessageBox]::Show("$Global:lineuri assigned to $Global:selecteduser.")
		Write-Host "$Global:lineuri assigned to $Global:selecteduser." -ForegroundColor Yellow
		}
	catch { 
		[void][System.Windows.Forms.MessageBox]::Show("Could not assign phone number. `nPlease check´n $Global:lineuri ´nif the value is correct. `nIt must be tel:+49..123.")	
		Write-Host "Could not assign phone number. Please check $Global:lineuri if the value is correct. It must be +49..123" -ForegroundColor Red
	}
}
#Release phone number (DIRECT ROUTING)
function ReleaseNumber {
	try { 
		Remove-CsPhoneNumberAssignment -Identity "$Global:selecteduser" -RemoveAll 
		Write-Host "Removed phone number for $Global:selecteduser" -ForegroundColor Yellow
		[void][System.Windows.Forms.MessageBox]::Show("$Global:selecteduser phone number removed and EV disabled")
		}
	catch { 
		[void][System.Windows.Forms.MessageBox]::Show("Could not remove phone number for $Global:selecteduser")	
		Write-Host "Could not remove phone number for $Global:selecteduser" -ForegroundColor Red
	}
}
#List online voice routing policis
function ListOVRPs {
	if ($Global:ovrpslistedonce -ne "yes"){
		$Global:ovrpslistedonce = "yes"
		$Global:Cassignvrp.Items.Clear()
		Write-Host "Loading online voice routing policies ..." -ForegroundColor Yellow
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
			[void][System.Windows.Forms.MessageBox]::Show("Could not find any online voice routing policy") 
			Write-Host "Could not find any online voice routing policy" -ForegroundColor Red
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
			[void][System.Windows.Forms.MessageBox]::Show("Could not select online voice routing policy") 
			Write-Host "Could not select online voice routing policy $Global:userovrp." -ForegroundColor Red
		}			
}
#Assign online voice routing policy
function AssignOVRP {
	try { 
		if($Global:userovrp -eq "Global"){
			Grant-CsOnlineVoiceRoutingPolicy -Identity $Global:selecteduser -PolicyName $null
			Write-Host "Assigned global OVRP to $Global:selecteduser" -ForegroundColor Yellow
		}
		else {
			Grant-CsOnlineVoiceRoutingPolicy -Identity $Global:selecteduser -PolicyName $Global:userovrp	
			Write-Host "Assigned $Global:userovrp to $Global:selecteduser" -ForegroundColor Yellow
		}		
	}
	catch { 
		[void][System.Windows.Forms.MessageBox]::Show("Could not assign online voice routing policy.") 
		Write-Host "Could not assign online voice routing policy to $Global:selecteduser" -ForegroundColor Red
	}			
}
#List calling policis
function ListCPs {
	if ($Global:cpslistedonce -ne "yes"){
		Write-Host "Loading calling policies ..." -ForegroundColor Yellow
		try {
			$Global:cpslistedonce = "yes"
			$Global:allcallingpolicies = Get-CsTeamsCallingPolicy
			$Global:cpscounter = ($Global:allcallingpolicies).count
			$Global:ipb3 = 0 #progresscounter
			$Global:allcallingpolicies | ForEach-Object {
				[void] $Cassigncp.Items.Add($_.Identity) 
				Write-Progress -Activity "Loading in calling policies ..." -Status "Progress" -PercentComplete ((($Global:ipb3++) / $Global:cpscounter) * 100)
			}
			Write-Progress -Activity "Loading in calling policies ..." -Status "Ready" -Completed	
		}
		catch { 
			[void][System.Windows.Forms.MessageBox]::Show("Could not find any calling policy") 
			Write-Host "Could not find any calling policy" -ForegroundColor Red
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
		$Global:usercp = $Cassigncp.SelectedItem	
		Write-Host "Selected calling policy: $Global:usercp" -ForegroundColor Yellow	
	}
	catch { 
		[void][System.Windows.Forms.MessageBox]::Show("Could not select calling policy.") 
		Write-Host "Could not select calling policy $Global:usercp." -ForegroundColor Red
	}		
}
#Assign calling policy
function AssignCP {
		Write-Host "Selected user: $Global:selecteduser" -ForegroundColor Yellow
		Write-Host "Selected calling policy: $Global:usercp" -ForegroundColor Yellow
	
	try { 
			if ($Global:usercp -eq "Global"){
				Grant-CsTeamsCallingPolicy -Identity $Global:selecteduser -PolicyName $null
				Write-Host "Assigned global calling policy to $Global:selecteduser" -ForegroundColor Yellow
			}
			else {
				Grant-CsTeamsCallingPolicy -Identity $Global:selecteduser -PolicyName $Global:usercp
				Write-Host "Assigned calling policy $Global:usercp to $Global:selecteduser" -ForegroundColor Yellow
			}
			
		}
	catch { 
		[void][System.Windows.Forms.MessageBox]::Show("Could not assign calling policy $Global:usercp to $Global:selecteduser")
		Write-Host "Could not assign calling policy $Global:usercp to $Global:selecteduser" -ForegroundColor Yellow 
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
		#progress bar preparation
		$index = 0
        $totalUsers = ($Global:allusers).Count
		#new empty csv object
		$csv = New-Object System.Collections.Generic.List[System.Object]
		#a loop to export all users to csv
		$Global:allusers | ForEach-Object {
			# Update the progress bar
            Write-Progress -Activity "Exporting users to CSV" -Status "$index of $totalUsers users exported" -PercentComplete ($index / $totalUsers * 100)
			$index++
			#create csvline custom object
			$csvline = [PSCustomObject]@{			
				UPN = $_.UserPrincipalName 
				SIP = $_.SipAddress 
				LineURI = $_.LineUri 
				OnlineVoiceRoutingPolicy = $_.OnlineVoiceRoutingPolicy 
				CallingPolicy = $_.TeamsCallingPolicy
			}			
			Write-Host $csvline -ForegroundColor Yellow
			$csv.Add($csvline)
		}  
		$csv | Export-Csv -Path $saveFileDialog.FileName -NoTypeInformation -Encoding UTF8
		#remove progress bar if done
		Write-Progress -Activity "Exporting users to CSV" -Status "Completed" -Completed	
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
	$Global:Cselectuser = New-Object System.Windows.Forms.ComboBox
	$Lselectuser = New-Object System.Windows.Forms.Label
	$Lassignvrp = New-Object System.Windows.Forms.Label
	$Global:Cassignvrp = New-Object System.Windows.Forms.ComboBox
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
	$Global:Cassignvrp.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$Global:Cassignvrp.FormattingEnabled = $true
	$Global:Cassignvrp.Location = New-Object System.Drawing.Point(148, 84)
	$Global:Cassignvrp.Name = "Cassignvrp"
	$Global:Cassignvrp.Size = New-Object System.Drawing.Size(356, 21)
	$Global:Cassignvrp.IntegralHeight = $true
	$Global:Cassignvrp.MaxDropDownItems = 15
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
		if (($null -eq $Global:currentlineuri) -or ($Global:currentlineuri -eq " ")){ $Tenterlineuri.Text = "e.g. +49711987456123" }
		else { $Tenterlineuri.Text = "$Global:currentlineuri" }
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
	$Lreleasenotes.Text = "V 0.4 Erik Kleefeldt January 2024"

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
	$FWindow.Controls.Add($Global:Cassignvrp)
	$FWindow.Controls.Add($Lselectuser)
	$FWindow.Controls.Add($Global:Cselectuser)
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
