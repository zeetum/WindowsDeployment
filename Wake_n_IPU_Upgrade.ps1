#### ---------- CONFIG ------------------------------
$OUPath = "OU=I.T. Office,OU=Block H,OU=Desktops,OU=School Managed,OU=Computers,OU=E5070S01,OU=Schools,DC=indigo,DC=schools,DC=internal"
$WOL_BC = "10.224.15.255"
$IP_IPv4Address = "10.224.9.0"
$IP_MASK = "255.255.248.0"
$CCMProgramID = "CAS002EF"
$WindowsVersion = "10.0.17134" ## Is Windows 10 1803

# get-wmiobject -query "SELECT * FROM CCM_Program" -namespace "ROOT\ccm\ClientSDK" | Out-GridView

### ------------ FUNCTIONS --------------------------
function Send-WOL {
    <# 
  .SYNOPSIS  
    Send a WOL packet to a broadcast address
  .PARAMETER mac
   The MAC address of the device that need to wake up
  .PARAMETER ip
   The IP address where the WOL packet will be sent to
  .EXAMPLE 
   Send-WOL -mac 00:11:32:21:2D:11 -ip 192.168.8.255 
#>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$mac,
        [string]$ip = "255.255.255.255", 
        [int]$port = 9
    )
    $broadcast = [Net.IPAddress]::Parse($ip)
 
    $mac = (($mac.replace(":", "")).replace("-", "")).replace(".", "")
    $target = 0, 2, 4, 6, 8, 10 | % { [convert]::ToByte($mac.substring($_, 2), 16) }
    $packet = (, [byte]255 * 6) + ($target * 16)
 
    $UDPclient = new-Object System.Net.Sockets.UdpClient
    $UDPclient.Connect($broadcast, $port)
    [void]$UDPclient.Send($packet, 102) 

}

Function Get-ADSIObject {
    <#
        .SYNOPSIS
            This function will query Active Directory using an ADSISearcher object.
        .PARAMETER DomainName
            Name of the domain to query.
        .PARAMETER LDAPFilter
            LDAP filter to use for the query.
        .PARAMETER Property
            Property to return.
        .PARAMETER PageSize
            PageSize to use for the query.
        .PARAMETER SearchBAse
            SearchBase to scope the query.
        .EXAMPLE
            Get-ADSIObject -Verbose
        .EXAMPLE
            Get-ADSIObject -NamingContext 'DC=D2K16,DC=itfordummies,DC=net' -LDAPFilter '(admincount=1)' -Verbose
        .EXAMPLE
            Get-ADSIObject -DomainName D2K12R2.itfordummies.net -LDAPFilter '(admincount=1)' -NamingContext 'DC=D2K12R2,DC=itfordummies,DC=net'
        .EXAMPLE
            Get-ADSIObject -Property Name,Mail,description -Verbose -SearchBase 'OU=Users,OU=Star Wars,OU=Prod,DC=D2K16,DC=itfordummies,DC=net' | Out-GridView
        .LINK
            https://ItForDummies.net
        .NOTES
            Futur updates : #Credential, Server, searchscope
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0)]
        [String]$LDAPFilter = '(objectclass=user)',

        [Parameter(Position = 1)]
        [String[]]$Property,

        [Parameter(Position = 2)]
        [ValidateScript({ Test-Connection -ComputerName $_ -Count 2 -Quiet })]
        [String]$DomainName = [DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name,

        [String]$SearchBase,

        [Int]$PageSize = 1000
    )

    DynamicParam {
        if ([String]::IsNullOrEmpty($DomainName)) { $DomainName = [DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name }
        
        $AttribColl = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParamAttrib = New-Object System.Management.Automation.ParameterAttribute
        $ParamAttrib.Mandatory = $false
        $ParamAttrib.ParameterSetName = '__AllParameterSets'
        $ParamAttrib.ValueFromPipeline = $false
        $ParamAttrib.ValueFromPipelineByPropertyName = $false
        $AttribColl.Add($ParamAttrib)
        $AttribColl.Add((New-Object System.Management.Automation.ValidateSetAttribute(([ADSI]"LDAP://$DomainName/RootDSE" | Select-Object -ExpandProperty namingContexts))))
        $RuntimeParam = New-Object System.Management.Automation.RuntimeDefinedParameter('NamingContext', [string], $AttribColl)
        $RuntimeParamDic = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $RuntimeParamDic.Add('NamingContext', $RuntimeParam)
        $RuntimeParamDic
    }
    
    Begin {
        $PsBoundParameters.GetEnumerator() | ForEach-Object -Process { New-Variable -Name $_.Key -Value $_.Value -ErrorAction 'SilentlyContinue' }
    }
    Process {
        $ADSISearcher = [ADSISearcher]"$LDAPFilter"
        #Load each property if requested
        if ($Property) {
            $Property | ForEach-Object -Process {
                Write-Debug -Message "Adding $_ to properties to load..."
                $ADSISearcher.PropertiesToLoad.Add($_.ToLower())
            } | Out-Null
        }
        
        #Use Naming Context if specified, otherwise, use the domain name
        if ($NamingContext) {
            Write-Debug -Message "Will use $NamingContext."
            $ADSISearcher.SearchRoot = [ADSI]"LDAP://$NamingContext"
        }
        elseif ($SearchBase) {
            Write-Debug -Message "Will use $SearchBase."
            $ADSISearcher.SearchRoot = [ADSI]"LDAP://$SearchBase"
        }
        else {
            Write-Debug -Message "Will use $DomainName."
            $ADSISearcher.SearchRoot = [ADSI]"LDAP://$DomainName"
        }
        
        #Set PageSize
        $ADSISearcher.PageSize = $PageSize
        Write-Debug -Message "Searching for $LDAPFilter in $DomainName with a pagesize of $PageSize..."
        $AllObjects = $ADSISearcher.FindAll()
        $LoadedProperties = $AllObjects | Select-Object -First 1 | Select-Object -ExpandProperty Properties | Select-Object -ExpandProperty PropertyNames

        #Going through each AD object
        Foreach ($Object in $AllObjects) {
            #Hashtable for storing properties
            $CurrentObj = @{}
            Foreach ($LoadedProperty in $LoadedProperties) {
                ##Adding each properties to the hashtable 
                $CurrentObj.Add($LoadedProperty, $($Object.Properties.Item($LoadedProperty)))
            }
            #Create an object per AD object with all properties
            New-Object -TypeName PSObject -Property $CurrentObj
        }
    }
    End {}
}

### ---------------- GET COMPUTERS FROM AD ---------
try {
    $ADComputers = Get-ADSIObject -SearchBase $OUPath -LDAPFilter "(objectclass=Computer)"

    ## Check Path has something in it
    if ($ADComputers.Count -eq 0) {
        Write-Error "AD Path Has No Computers in it!"
        break
    }

}
catch {
    Write-Error "ADSIObject: Failed to Get Objects from AD"
}

### ---------------- WAKE COMPUTERS -----------------
### Uses AD Computer Path, Wakes all devices
foreach ($_ in $ADComputers) {

    ### FIND JSON FILE

    if ((Test-Path -Path ".\SCCMAutoDeploy\Devices\$($_.DNSHostName).JSON") -eq $false) {
        #Write-Error "Audit: File Not Existing .\.\SCCMAutoDeploy\Devices\$($_.DNSHostName).JSON"
        Continue
    }

    ### FIND MAC from File
    try {
        $MACAddress = (Get-Content -Path ".\SCCMAutoDeploy\Devices\$($_.DNSHostName).JSON" | ConvertFrom-Json).MAC
    }
    catch {
        Write-Error "Audit: Failed to get content of JSON File .\SCCMAutoDeploy\Devices\$($_.DNSHostName).JSON"
    }

    ## ---- Check MAC Not Null
    if ($MACAddress -eq $null -or $MACAddress -eq "") {
        Write-Host "MAC Address is Null, Skipping"
        Continue
    }

    ## ----- Send WOL ---------
    try {
        Write-Host "WOL: Sent to $($_.DNSHostName) | $($MACAddress)"
        Send-WOL -ip $WOL_BC -mac $MACAddress -port 9
        Send-WOL -ip $WOL_BC -mac $MACAddress -port 9
        Send-WOL -ip $WOL_BC -mac $MACAddress -port 9
        Send-WOL -ip $WOL_BC -mac $MACAddress -port 7
        Send-WOL -ip $WOL_BC -mac $MACAddress -port 7
        Send-WOL -ip $WOL_BC -mac $MACAddress -port 7
    }
    catch {
        Write-Error "WOL: Failed to Sent Wake Packet, Skipping"
        Continue
    }

    ## ------ END FOREACH ------------------------
}

### -------- WAIT -----------
Write-Host "Waiting 120 Seconds"
#Sleep -Seconds 120

### ----------------- Wait and Run SCCM Task Sequence --------
foreach ($_ in $ADComputers) {

    ## Check Online State
    if ((Test-Connection -ComputerName $_.DNSHostName -Count 10 -Quiet) -eq $false) {
        Write-Error ("Connection: Host $($_.DNSHostName) Not Online after 10 Tries")
        Continue
    }

    try {
        $IPUTask = (get-wmiobject -query "SELECT * FROM CCM_Program" -namespace "ROOT\ccm\ClientSDK" -ComputerName $_.DNSHostName) | Where-Object { $_.Name -like "*20H2*" }
        Invoke-WmiMethod -Class CCM_ProgramsManager -Namespace "root\ccm\clientsdk" -ComputerName $_.DNSHostName -Name ExecutePrograms -argumentlist $IPUTask

        Write-Host "Running $($CCMProgramID) Task Sequence"
    }
    catch {
        Write-Host "Failed to Get CCM_Program Data/ Execute the Task Sequence"
    }


    ## END FOREACH
}
