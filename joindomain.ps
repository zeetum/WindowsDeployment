$dojoin = Read-Host 'Do you wish to join the school domain (yes or no)'

if($dojoin.ToLower() -like "no") {
Restart-Computer
}

$user = Read-Host 'Input the user ID with authority to add'
$domuser = "indigo\"+$user

$securedpwrd = Read-Host -AsSecureString 'Input the password' 
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securedpwrd)
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

Write-Host "Please enter your desired location [1-2] [Default 1]:
1. 2014 SOSE Science DEll Inspiron 11
2. 2018 SEQTA Dell Inspiron 11"
$ou = Read-Host

$validate = $false
if ($ou -eq "1") { $ou = "OU=2014 SOSE Science Dell Inspiron 11,OU=Notebooks,OU=School Managed,OU=Computers,OU=E4033S01,OU=Schools,DC=indigo,DC=schools,DC=internal"; $validate = $true }
if ($ou -eq "2") { $ou = "OU=2018 SEQTA Dell Inspiron 11,OU=Notebooks,OU=School Managed,OU=Computers,OU=E4033S01,OU=Schools,DC=indigo,DC=schools,DC=internal"; $validate = $true }
if ($validate -eq $false) { Write-Host "Invalid input, defaulting to Unassigned OU"; $ou = "OU=Unassigned,OU=Computers,OU=E4033S01,OU=Schools,DC=indigo,DC=schools,DC=internal"}

$credentials = New-Object System.Management.Automation.PsCredential($domuser, (ConvertTo-SecureString $password -AsPlainText -Force))
Write-Host "Adding this computer to the domain"
Add-Computer -DomainName "indigo.schools.internal" -Credential $credentials -OUPath $ou
