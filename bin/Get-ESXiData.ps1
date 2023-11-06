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


        [PSCustomObject]@{
            Name          = $_.Name
            VMName        = $IXVMProperties.VMName
            Version       = $_.Version
            Build         = $_.Build
            BootTime      = $IXVMProperties.BootTime
            IsConnected   = $_.IsConnected
            PowerState    = $IXVMProperties.PowerState
            OverallStatus = $IXVMProperties.OverallStatus
            IPv4Addresses = $IXVMProperties.'IP Addresses'
            CPUs          = $IXVMProperties.CPUs
            Memory        = $IXVMProperties.Memory
            ESXiHost      = $IXVMProperties.Host
            Cluster       = $IXVMProperties.ClusterName
            Datastore     = $IXVMProperties.DatastoreName
            Notes         = $IXVMProperties.Notes
        }
