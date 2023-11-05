@{
    Web = @{
        Static = @{
            Cache = @{
                Enable = $true
            }
        }
    }
    DebugLevel  = 'Info'
    PSModules   = 'PSHTML', 'mySQLite', 'Pode', 'Pode.Web'
    PSXi = @{
        AppName = 'PSXi App'
        Version = '1.1.5'
        Group1  = 'Classic'
        Group2  = 'Cloud'
        Group3  = 'Hyper-V'
        Tables  = @(
            'classic_summary' 
            'cloud_summary' 
            'classic_ESXiHosts'
            'cloud_ESXiHosts'
            'classic_ESXiHostsNotes'
            'cloud_ESXiHostsNotes'
            'classic_Datastores'
            'cloud_Datastores'
            'hyperv_SCVMHosts'
        )
        Views = @(
            'view_classic_ESXiHosts' 
            'view_cloud_ESXiHosts' 
            'view_hyperv_SCVMHosts'
        )
        # VMware
        vmwESXiHeader = @(
            'HostName'
            'Manufacturer'
            'Model'
            'Version'
            # 'Cluster'
            'PhysicalLocation'
            'ConnectionState'
            'Notes'
        )
        # VMware
        vmwDatastoreHeader = @(
            # 'vCenterServer'
            # 'DatastoreCluster'
            'DatastoreName'
            'DatastoreFolder'
            'ClusterStatus'
            # 'Type'
            'CapacityGB'
            'FreeSpaceGB'
            'Free'
        )
        # VMware
        vmwNetworkHeader = @(
            'vCenterServer'
            'NetworkName'
            'NetworkType'
            'NetworkFolder'
            'VDSwitch'
            'NetworkStatus'
        )
        # Hyper-V
        hvHostHeader = @(
            'HostName'
            'Manufacturer'
            'Model'
            'Version'
            # 'VMMServer'
            # 'Cluster'
            'PhysicalLocation'
            'HyperVState'
            'Notes'
        )
    }
}