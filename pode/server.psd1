@{
    Web = @{
        Static = @{
            Cache = @{
                Enable = $true
            }
        }
    }
    DebugLevel  = 'Error'
    PSModules   = 'PSHTML', 'mySQLite', 'Pode', 'Pode.Web'
    PSXi = @{
        AppName = 'PSXi App'
        Version = '1.0.6'
        Group1  = 'Classic'
        Group2  = 'Cloud'
        Tables  = @(
            'classic_summary' 
            'cloud_summary' 
            'classic_ESXiHosts' 
            'cloud_ESXiHosts'
        )
        TableHeader = @(
            'HostName'
            'Manufacturer'
            'Model'
            'Version'
            'Cluster'
            'PhysicalLocation'
            'ConnectionState'
            'Notes'
        )
    }
}