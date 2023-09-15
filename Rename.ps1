#Get a list of Network Adapters that are Physical and connected to the PCI bus
$NICs = Get-WmiObject -Class Win32_NetworkAdapter | Where-Object -FilterScript {$PSItem.PhysicalAdapter} | Where-Object { $PSItem.PNPDeviceID -like "PCI\*" }
   
$MACAddress = ""
if ($NICs | Where-Object { $PSItem.NetConnectionID -eq "Ethernet" }) {
    $MACAddress = @($NICs | Where-Object { $PSItem.NetConnectionID -like "Ethernet" })[0].MACAddress.Replace(':','')
} elseif ($NICs | Where-Object { $PSItem.NetConnectionID -eq "WiFi" }) {
    $MACAddress = @($NICs | Where-Object { $PSItem.NetConnectionID -like "WiFi" })[0].MACAddress.Replace(':','')
} elseif ($NICs | Where-Object { $PSItem.NetConnectionID -eq "Wi-Fi" }) {
    $MACAddress = @($NICs | Where-Object { $PSItem.NetConnectionID -like "Wi-Fi" })[0].MACAddress.Replace(':','')
}

if ($MACAddress) {
    Rename-Computer -NewName "MS$MACAddress" -Force
}
#Restart-Computer
