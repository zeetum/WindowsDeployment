# Returns the selected site code
function Choose-SiteCode() {
	$domColour = "indigo"
	$SiteCodes = @('5008','5167','5070')
	$len = $SiteCodes.length
	if ($len -eq 1) {
		return $SiteCodes[0]
	}

	Add-Type -AssemblyName System.Windows.Forms
	Add-Type -AssemblyName System.Drawing
	$ChooseForm = New-Object System.Windows.Forms.Form
	$ChooseForm.Text = 'Choose Site Code'
	$ChooseForm.Size = New-Object System.Drawing.Size(295,(95 + $len * 22))
	$ChooseForm.StartPosition = 'CenterScreen'
	$ChooseForm.FormBorderStyle = 'FixedDialog'
	$ChooseForm.ControlBox = $False

	$listBox = New-Object System.Windows.Forms.ListBox
	$listBox.Location = New-Object System.Drawing.Point(10,10)
	$listBox.Size = New-Object System.Drawing.Size(260,30)
	$listBox.Height = 24 * $len
	$listBox.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Regular)
	foreach ($item in $SiteCodes) {
		$listBox.Items.Add($item)
	}
	$ChooseForm.Controls.Add($listBox)

	$okButton = New-Object System.Windows.Forms.Button
	$okButton.Location = New-Object System.Drawing.Point(10,(19 + $len * 22))
	$okButton.Size = New-Object System.Drawing.Size(126,30)
	$okButton.Text = 'Set'
	$okButton.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Regular)
	$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
	$ChooseForm.AcceptButton = $okButton
	$ChooseForm.Controls.Add($okButton)

	$cancelButton = New-Object System.Windows.Forms.Button
	$cancelButton.Location = New-Object System.Drawing.Point(143,(19 + $len * 22))
	$cancelButton.Size = New-Object System.Drawing.Size(126,30)
	$cancelButton.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Regular)
	$cancelButton.Text = 'Auto'
	$cancelButton.DialogResult = "Cancel"
	$ChooseForm.CancelButton = $cancelButton
	$ChooseForm.Controls.Add($cancelButton)

	$ChooseForm.Topmost = $true

	do {
		$action = $ChooseForm.ShowDialog()
		if ($action -eq "Cancel") { return 0 }
		$SiteCode = $listBox.SelectedItem
	} while (!$SiteCode)

	return  @($domColour, $SiteCode)
}

# Returns the hostname of the DHCP server
# (Resolve-DnsName ((Resolve-DnsName "rodc.site.internal").IPAddress)).NameHost
function GetLocalDomainController() {
	Write-Host "`nConnecting...."
	$DHCPServer = Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "DHCPEnabled=$true" | Select DHCPServer
	$DHCPServer = ($DHCPServer.DHCPServer | Out-String).Trim()

	try {
		$LocalDC = Resolve-DnsName($DHCPServer)
		$LocalDC = $LocalDC.NameHost.Trim()
	} catch {
		$LocalDC = ""
	}
	
	if ($LocalDC) {
		Write-Host "Local Server: "$DHCPServer
	} else {
		Write-Host "Connection Failed"
	}

	return $LocalDC
}

# Returns if the username and password validate against the domain
function TestCredentials($domain, $username, $password) {
	if ($domain.split(".").Length -ne 4) {
		Write-Host "Domain Name Failed"
		return 0
	}
	Write-Host "Authenticating: "$domain

	try {
		Add-Type -AssemblyName System.DirectoryServices.AccountManagement
		$ContextType = [System.DirectoryServices.AccountManagement.ContextType]::Domain
		$PrincipalContext = [System.DirectoryServices.AccountManagement.PrincipalContext]::new($ContextType, $domain)
		$valid = $PrincipalContext.ValidateCredentials($username,$password, "Negotiate")
	} catch {
		$valid = 0
	}

	return $valid
}

# Returns valid username, password and domain
function GetCredentials() {

	Add-Type -AssemblyName System.Windows.Forms
	Add-Type -AssemblyName System.Drawing
	$CredentialsForm = New-Object System.Windows.Forms.Form
	$CredentialsForm.Text = 'Enter Administrator Credentials'
	$CredentialsForm.Size = New-Object System.Drawing.Size(344,230)
	$CredentialsForm.StartPosition = 'CenterScreen'
	$CredentialsForm.FormBorderStyle = 'FixedDialog'

	$usernameLabel = New-Object System.Windows.Forms.label
	$usernameLabel.Location = New-Object System.Drawing.Size(7,12)
	$usernameLabel.width = 100
	$usernameLabel.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Regular)
	$usernameLabel.Text = "Username"
	$CredentialsForm.Controls.Add($usernameLabel)

	$usernameInput = New-Object System.Windows.Forms.TextBox
	$usernameInput.Location = New-Object System.Drawing.Point(117,10)
	$usernameInput.Size = New-Object System.Drawing.Size(200,20)
	$usernameInput.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Regular)
	$CredentialsForm.Controls.Add($usernameInput)

	$passwordLabel = New-Object System.Windows.Forms.label
	$passwordLabel.Location = New-Object System.Drawing.Size(7,52)
	$passwordLabel.width = 100
	$passwordLabel.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Regular)
	$passwordLabel.Text = "Password"
	$CredentialsForm.Controls.Add($passwordLabel)

	$passwordInput = New-Object System.Windows.Forms.MaskedTextBox
	$passwordInput.PasswordChar = '*'
	$passwordInput.Location = New-Object System.Drawing.Point(117,50)
	$passwordInput.Size = New-Object System.Drawing.Size(200,20)
	$passwordInput.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Regular)
	$CredentialsForm.Controls.Add($passwordInput)

	$DCPrompt = New-Object System.Windows.Forms.label
	$DCPrompt.Location = New-Object System.Drawing.Size(10,90)
	$DCPrompt.width = 300
	$DCPrompt.text = "Domain Controller:"
	$DCPrompt.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Regular)
	$CredentialsForm.Controls.Add($DCPrompt)

	$selectDCButton = New-Object System.Windows.Forms.Button
	$selectDCButton.Location = New-Object System.Drawing.Point(15,115)
	$selectDCButton.Size = New-Object System.Drawing.Size(28,28)
	$selectDCButton.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Regular)

	$localDCLabel = New-Object System.Windows.Forms.label
	$localDCLabel.Location = New-Object System.Drawing.Size(50,120)
	$localDCLabel.width = 280
	$localDCLabel.Font = New-Object System.Drawing.Font("Arial",11,[System.Drawing.FontStyle]::Regular)
	$CredentialsForm.Controls.Add($localDCLabel)

	$global:manualDC = $false
	$selectDCButton.Text = [char]0x2B1C
	$selectDCButton.Add_Click({
		$siteDetails = Choose-SiteCode
		if ($siteDetails.count -eq 5) {
			$global:manualDC = $true
			$DomainController = "e" + $siteDetails[4] + "s01sv001." + $siteDetails[3] + ".schools.internal"
			$localDCLabel.Text = $DomainController
			$selectDCButton.Text = [char]0x2B1B
		} else {
			$localDCLabel.Text = ""
			$selectDCButton.Text = [char]0x2B1C
			$global:manualDC = $false
			$DomainController = GetLocalDomainController
			$localDCLabel.Text = $DomainController
		}
	})
	$CredentialsForm.Controls.Add($selectDCButton)

	$okButton = New-Object System.Windows.Forms.Button
	$okButton.Location = New-Object System.Drawing.Point(15,150)
	$okButton.Size = New-Object System.Drawing.Size(145,30)
	$okButton.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Regular)
	$okButton.Text = 'Connect'
	$okButton.DialogResult = "OK"
	$CredentialsForm.AcceptButton = $okButton
	$CredentialsForm.Controls.Add($okButton)

	$cancelButton = New-Object System.Windows.Forms.Button
	$cancelButton.Location = New-Object System.Drawing.Point(170,150)
	$cancelButton.Size = New-Object System.Drawing.Size(145,30)
	$cancelButton.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Regular)
	$cancelButton.Text = 'Cancel'
	$cancelButton.DialogResult = "Cancel"
	$CredentialsForm.CancelButton = $cancelButton
	$CredentialsForm.Controls.Add($cancelButton)

	do {
		$DomainController = GetLocalDomainController
		
		if ($DomainController -eq "") {
			$usernameInput.BackColor = 'White'
			$passwordInput.BackColor = 'White'

			$okButton.BackColor = "IndianRed"
			$okButton.Text = "Retry"
		} else {
			$okButton.BackColor = "Green"
			$okButton.Text = "Connect"
		}

		if (!$global:manualDC) {
			$localDCLabel.Text = $DomainController
		}

		$action = $CredentialsForm.ShowDialog()
		if ($action -eq "Cancel") { exit }
		$CredentialsForm.Add_Shown({$CredentialsForm.Activate(); $usernameInput.focus()})

		$validate = TestCredentials -domain $DomainController -username $usernameInput.Text -password $passwordInput.Text
		if (!$validate -and $DomainController) {
			$usernameInput.Text = ''
			$passwordInput.Text = ''
			$usernameInput.BackColor = 'IndianRed'
			$passwordInput.BackColor = 'IndianRed'
		}
	} while (!$validate)

	return @{'username' = $username; "password" = $password; "localDC" = $DomainController}
}

Export-ModuleMember -Function GetCredentials
