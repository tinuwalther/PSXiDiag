#region Connect to VMM
$VMM = Get-SCVMMServer -ComputerName $VMMServer -TCPPort 8100
$VMM.Name
$VMM.ActiveVMMNode
$VMM.ManagedComputer.FQDN
#endregion

#region Get Cluster - Playground
$hvCluster = Get-SCVMHostCluster
foreach($cluster in $hvCluster){
    $cluster.Nodes | ForEach-Object {
        [PSCustomObject]@{
            Name             = $_.Name
            OSVersion        = $_.OperatingSystem.Name
            HyperVVersion    = $_.HyperVVersion
            Manufacturer     = ''
            Model            = ''
            VMMServer        = $VMM.Name
            Cluster          = $cluster.ClusterName
            PhysicalLocation = $cluster.HostGroup.Name
            HyperVState      = $_.HyperVState
            Notes            = ''
        }
    }
}
#endregion

#region Get Hosts
$hvHosts   = Get-SCVMHost
foreach($node in $hvHosts){
    $hvCluster = Get-SCVMHostCluster -VMHostGroup $node.VMHostGroup
    [PSCustomObject]@{
        Name             = $node.Name
        #OSVersion        = $node.OperatingSystem.Name
        HyperVVersion    = $node.HyperVVersion
        Manufacturer     = ''
        Model            = ''
        VMMServer        = $VMM.Name
        Cluster          = $hvCluster.ClusterName
        PhysicalLocation = $node.VMHostGroup.Name
        HyperVState      = $node.HyperVState
        Notes            = $node.Custom1
    }
}

# Custom propeties
Custom1 
Custom2 
Custom3 
Custom4 
Custom5 
Custom6 
Custom7 
Custom8 
Custom9 
Custom10
#endregion
