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
        Version = '1.1.2'
        Group1  = 'Classic'
        Group2  = 'Cloud'
        Tables  = @(
            'classic_summary' 
            'cloud_summary' 
            'classic_ESXiHosts'
            'cloud_ESXiHosts'
            'classic_ESXiHostsNotes'
            'cloud_ESXiHostsNotes'
        )
        Views = @(
            'view_classic_ESXiHosts' 
            'view_cloud_ESXiHosts' 
        )
        TableHeader = @(
            'HostName'
            'Manufacturer'
            'Model'
            'Version'
            # 'Cluster'
            'PhysicalLocation'
            'ConnectionState'
            'Notes'
        )
    }
}