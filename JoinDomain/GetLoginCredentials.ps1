
function GetLocalDomainController() {
    $DHCPServer = Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "DHCPEnabled=$true" | Select DHCPServer
    $DHCPServer = $DHCPServer.DHCPServer | Out-String
    $LocalDC = [System.Net.Dns]::GetHostByAddress($DHCPServer.Trim()).HostName

    return "e5070s01sv001.indigo.schools.internal"
    #return ""
}

function GetCredentials() {
    # an exit flag for events
    $exit = 0

	Add-Type -AssemblyName System.Windows.Forms
	Add-Type -AssemblyName System.Drawing
	$form = New-Object System.Windows.Forms.Form
	$form.Text = 'Enter Administrator Credentials'
	$form.Size = New-Object System.Drawing.Size(350,240)
	$form.StartPosition = 'CenterScreen'

	$usernameLabel = New-Object System.Windows.Forms.label
	$usernameLabel.Location = New-Object System.Drawing.Size(7,12)
	$usernameLabel.width = 100
	$usernameLabel.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Regular)
	$usernameLabel.Text = "Username"
	$form.Controls.Add($usernameLabel)

    $usernameInput = New-Object System.Windows.Forms.TextBox
    $usernameInput.Location = New-Object System.Drawing.Point(117,10)
    $usernameInput.Size = New-Object System.Drawing.Size(200,20)
    $usernameInput.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Regular)
    $form.Controls.Add($usernameInput)

	$passwordLabel = New-Object System.Windows.Forms.label
	$passwordLabel.Location = New-Object System.Drawing.Size(7,52)
	$passwordLabel.width = 100
	$passwordLabel.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Regular)
	$passwordLabel.Text = "Password"
	$form.Controls.Add($passwordLabel)

    $passwordInput = New-Object System.Windows.Forms.TextBox
    $passwordInput.Location = New-Object System.Drawing.Point(117,50)
    $passwordInput.Size = New-Object System.Drawing.Size(200,20)
    $passwordInput.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Regular)
    $form.Controls.Add($passwordInput)

	$DCPrompt = New-Object System.Windows.Forms.label
	$DCPrompt.Location = New-Object System.Drawing.Size(10,90)
	$DCPrompt.width = 300
    $DCPrompt.text = "Local Domain Controller:"
	$DCPrompt.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Regular)
	$form.Controls.Add($DCPrompt)

    $localDCLabel = New-Object System.Windows.Forms.label
	$localDCLabel.Location = New-Object System.Drawing.Size(10,120)
	$localDCLabel.width = 300
	$localDCLabel.Font = New-Object System.Drawing.Font("Arial",11,[System.Drawing.FontStyle]::Regular)
	$form.Controls.Add($localDCLabel)

	$okButton = New-Object System.Windows.Forms.Button
	$okButton.Location = New-Object System.Drawing.Point(20,160)
	$okButton.Size = New-Object System.Drawing.Size(140,30)
    $okButton.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Regular)
	$okButton.Text = 'Connect'
    $okButton.DialogResult = "OK"
	$form.AcceptButton = $okButton
	$form.Controls.Add($okButton)

	$cancelButton = New-Object System.Windows.Forms.Button
	$cancelButton.Location = New-Object System.Drawing.Point(170,160)
	$cancelButton.Size = New-Object System.Drawing.Size(140,30)
	$cancelButton.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Regular)
	$cancelButton.Text = 'Cancel'
    $cancelButton.DialogResult = "Cancel"
    $form.CancelButton = $cancelButton
    $form.Controls.Add($cancelButton)

    do {
        $DomainControllerFQDN = GetLocalDomainController
        $localDCLabel.Text = $DomainControllerFQDN
        if ($DomainControllerFQDN -eq "") {
            $okButton.Text = "Retry"
        } else {
            $okButton.Text = "Connect"
        }
        $action = $form.ShowDialog()
        if ($action -eq "Cancel") {return 0}

        $username = $usernameInput.Text
        $password = $passwordInput.Text
        
	} while ($DomainControllerFQDN -eq "")


	return @{'username' = $username; "password" = $password; "localDC" = $DomainControllerFQDN}
} # Site Function Choose-SiteCode

GetCredentials