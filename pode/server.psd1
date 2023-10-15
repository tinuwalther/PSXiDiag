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
        Version = '1.1.4'
        Group1  = 'Classic'
        Group2  = 'Cloud'
        Tables  = @(
            'classic_summary' 
            'cloud_summary' 
            'classic_ESXiHosts'
            'cloud_ESXiHosts'
            'classic_ESXiHostsNotes'
            'cloud_ESXiHostsNotes'
            'classic_Datastores'
            'cloud_Datastores'
        )
        Views = @(
            'view_classic_ESXiHosts' 
            'view_cloud_ESXiHosts' 
        )
        ESXiHeader = @(
            'HostName'
            'Manufacturer'
            'Model'
            'Version'
            # 'Cluster'
            'PhysicalLocation'
            'ConnectionState'
            'Notes'
        )
        DatastoreHeader = @(
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
    }
}