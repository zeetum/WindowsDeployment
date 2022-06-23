# Returns the selected site code
function Choose-SiteCode() {
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
	$okButton.Text = 'Join'
	$okButton.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Regular)
	$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
	$ChooseForm.AcceptButton = $okButton
	$ChooseForm.Controls.Add($okButton)

	$cancelButton = New-Object System.Windows.Forms.Button
	$cancelButton.Location = New-Object System.Drawing.Point(143,(19 + $len * 22))
	$cancelButton.Size = New-Object System.Drawing.Size(126,30)
	$cancelButton.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Regular)
	$cancelButton.Text = 'Cancel'
	$cancelButton.DialogResult = "Cancel"
	$ChooseForm.CancelButton = $cancelButton
	$ChooseForm.Controls.Add($cancelButton)

	$ChooseForm.Topmost = $true

	do {
		$action = $ChooseForm.ShowDialog()
		if ($action -eq "Cancel") { return 0 }
		$SiteCode = $listBox.SelectedItem
	} while (!$SiteCode)

	return $SiteCode
}

# Returns the hostname of the DHCP server
function GetLocalDomainController() {
	$DHCPServer = Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "DHCPEnabled=$true" | Select DHCPServer
	$DHCPServer = ($DHCPServer.DHCPServer | Out-String).Trim()
	Write-Host "Server IP: "$DHCPServer

	try {
		$LocalDC = Resolve-DnsName($DHCPServer)
		$LocalDC = $LocalDC.NameHost.Trim()
	} catch {
		$LocalDC = ""
	}
	
	return $LocalDC
}

# Returns if the username and password validate against the domain
function TestCredentials($domain, $username, $password) {
	if ($domain.split(".").Length -ne 4) {
		Write-Host "Domain Name Failed"
		return 0
	}

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
	$DCPrompt.text = "Local Domain Controller:"
	$DCPrompt.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Regular)
	$CredentialsForm.Controls.Add($DCPrompt)

	$localDCLabel = New-Object System.Windows.Forms.label
	$localDCLabel.Location = New-Object System.Drawing.Size(10,120)
	$localDCLabel.width = 280
	$localDCLabel.Font = New-Object System.Drawing.Font("Arial",11,[System.Drawing.FontStyle]::Regular)
	$CredentialsForm.Controls.Add($localDCLabel)

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
			$okButton.Text = "Retry"
			$localDCLabel.Text = [char]0x2716
			$localDCLabel.ForeColor = "IndianRed"
			$localDCLabel.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Regular)
		} else {
			$okButton.Text = "Connect"
			$localDCLabel.Text = $DomainController
			$localDCLabel.ForeColor = "black"
			$localDCLabel.Font = New-Object System.Drawing.Font("Arial",11,[System.Drawing.FontStyle]::Regular)
		}

		$action = $CredentialsForm.ShowDialog()
		if ($action -eq "Cancel") { exit }
		$CredentialsForm.Add_Shown({$CredentialsForm.Activate(); $usernameInput.focus()})

		if ($usernameInput.Text.Contains("\")) {
			$SiteCode = Choose-SiteCode
			if (!$SiteCode[-1]) { continue }
			$DomainController = "e" + $SiteCode[-1] + "s01sv001." + $usernameInput.Text.split("\")[0] + ".schools.internal"
			$username = $usernameInput.Text.split("\")[1]
		} else {
			$username = $usernameInput.Text
		}
		$password = $passwordInput.Text

		Write-Host "Server FQDN: "$DomainController
		$validate = TestCredentials -domain $DomainController -username $username -password $password
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
