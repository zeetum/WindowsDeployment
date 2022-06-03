function GetCredentials() {
	Add-Type -AssemblyName System.Windows.Forms
	Add-Type -AssemblyName System.Drawing
	$form = New-Object System.Windows.Forms.Form
	$form.Text = 'Enter Administrator Credentials'
	$form.Size = New-Object System.Drawing.Size(350,200)
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

	$okButton = New-Object System.Windows.Forms.Button
	$okButton.Location = New-Object System.Drawing.Point(10,120)
	$okButton.Size = New-Object System.Drawing.Size(260,23)
	$okButton.Text = 'Connect or Retry'
	$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
	$form.AcceptButton = $okButton
	$form.Controls.Add($okButton)

    do {
        $connected = get-wmiobject win32_networkadapter -filter "netconnectionstatus = 2"
		$form.ShowDialog()
        $username = $usernameInput.Text
        $password = $passwordInput.Text
	} while (!$connected)

	return @{'username' = $username; "password" = $password}
} # Site Function Choose-SiteCode

GetCredentials
