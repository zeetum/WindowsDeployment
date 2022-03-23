<#
Author: Luke Marshall
Date: 11/7/19

Joins AD with Deployment Admin Account and dumps itself into the MDT UnAssitnede folder so the policies apply

use powershell.exe -executionpolicy bypass -file .\ps2exe.ps1 -inputFile ".\ChangeHostname.ps1" -outputFile ".\ChangeHostname.exe" to create exe version of script.

# Export Wireless Settings if you don't already have them
netsh wlan export profile name=WIRELESS-5 folder=C:\

# Import Wireless Settings so we can connect to the domain
net start wlansvc
netsh wlan add profile filename=<working_directory>\Wi-Fi-WIRELESS-5.xml

#>

## Bad Pracitice but automation
$secpasswd = ConvertTo-SecureString -AsPlainText "<Service Account Password>" -Force
$credential = New-Object System.Management.Automation.PSCredential("indigo\<Service Account>", $secpasswd)

## Join Domain
$Join = Add-Computer -domainname "indigo.schools.internal" -OUPath "OU=MDTUnAssigned,OU=Desktops,OU=School Managed,OU=Computers,OU=E5008S01,OU=Schools,DC=indigo,DC=schools,DC=internal" -cred $credential -passthru -verbose

## Reboot in 30 Seconds
if($Join.HasSucceeded -eq $true){
}
else{
#try if host has joined the domain before
$Join = Add-Computer -domainname "indigo.schools.internal" -cred $credential -passthru -verbose
}

if($Join.HasSucceeded -eq $true){
Write-Host "Domain Joined!"

}
else{
Write-Error "Domain Join Failed!"
Write-Error "Wait for Technical Support before continuing!"
pause
}
# Finished
