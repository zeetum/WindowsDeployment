#Get a list of Network Adapters that are Physical and connected to the PCI bus
$NICs = Get-WmiObject -Class Win32_NetworkAdapter | Where-Object -FilterScript {$PSItem.PhysicalAdapter} | Where-Object { $PSItem.PNPDeviceID -like "PCI\*" }
# USB Ethernet adapters and the Surface Dock Ethernet adapter have a VendorID starting with USB.
# Therefore, using PCI should eliminate all Ethernet adapters that are not connected using a PCI connection
   
$MACAddress = ""
If ($NICs | Where-Object { $PSItem.NetConnectionID -eq "WiFi" }) {
    $MACAddress = @($NICs | Where-Object { $PSItem.NetConnectionID -like "WiFi" })[0].MACAddress.Replace(':','')
} ElseIf ($NICs | Where-Object { $PSItem.NetConnectionID -eq "Ethernet" }) {
    $MACAddress = @($NICs | Where-Object { $PSItem.NetConnectionID -like "Ethernet" })[0].MACAddress.Replace(':','')
}

If ($MACAddress) {
    Rename-Computer -NewName "MS$MACAddress" -Force
}
#Restart-Computer
