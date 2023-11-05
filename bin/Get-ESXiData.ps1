#region Connect to vCenter Server
$VIServer     = 'myvcenterserver.local'
$VICredential = Get-Credential
Connect-VIServer $VIServer -Credential $VICredential
#endregion

#region Get ESXiHosts
$vmHosts = Get-VMHost -Location 'MyDatacenter'
foreach($node in $vmHosts){
    [PSCustomObject]@{
        HostName         = $node.Name
        Version          = $node.Version
        Manufacturer     = ''
        Model            = ''
        vCenterServer    = ''
        Cluster          = ''
        PhysicalLocation = ''
        ConnectionState  = ''
        Notes            = ''
    }
}
#endregion
