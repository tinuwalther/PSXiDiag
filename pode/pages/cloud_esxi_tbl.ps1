Add-PodeWebPage -Group 'Cloud' -Name 'Cloud ESXi Host Table' -Title 'Cloud ESXi Host Inventory' -Icon 'server' -ScriptBlock {
    #region module
    if(-not(Get-InstalledModule -Name mySQLite -ea SilentlyContinue)){
        Install-Module -Name mySQLite -Force
        $Error.Clear()
    }
    if(-not(Get-Module -Name mySQLite)){ Import-Module -Name mySQLite }
    #endregion

    Set-PodeWebBreadcrumb -Items @(
        New-PodeWebBreadcrumbItem -Name 'Home' -Url '/'
        New-PodeWebBreadcrumbItem -Name 'Cloud ESXi Host Inventory' -Url '/pages/PageName?value=Cloud ESXi Hosts Table' -Active
    )
    
    $PodeRoot = $($PSScriptRoot).Replace('pages','db')
    $PodeDB   = Join-Path $PodeRoot -ChildPath 'psxi.db'
    $SqlTableName = 'cloud_ESXiHost', 'cloud_summary'

    if(Test-Path $PodeDB){

        New-PodeWebContainer -NoBackground -Content @(
            
            # $PSModule = Get-Module -ListAvailable pode*
            # New-PodeWebCard -Name 'Module check' -Content @(
            #     foreach($module in $PSModule){
            #         New-PodeWebAlert -Value "Module: $($module.Name), Version: $($module.Version)" -Type Info
            #     }
            # )

            $TableExists = foreach($item in $SqlTableName){
                $SqliteQuery = "SELECT * FROM sqlite_master WHERE name like '$item'"
                Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
            }
            if([String]::IsNullOrEmpty($TableExists)){
                New-PodeWebCard -Name 'Warning' -Content @(
                    New-PodeWebAlert -Value "Could not find table in $($PodeDB)" -Type Warning
                    New-PodeWebAlert -Value 'Please upload cloud_ESXiHost.csv and cloud_Summary.csv' -Type Important
                )
            }else{
                $MySQLiteDB   = Open-MySQLiteDB -Path $PodeDB
                if([String]::IsNullOrEmpty($MySQLiteDB)){
                    New-PodeWebCard -Name 'Warning' -Content @(
                        New-PodeWebAlert -Value "Could not connect to $($PodeDB)" -Type Warning
                    )
                }else{
                    $i = $ii = 200
                    $SqlTableName = 'cloud_ESXiHosts'
                    $SqliteQuery  = "Select * from $($SqlTableName)"
                    $FullDB       = Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
                    $VIServer     = $FullDB | Group-Object vCenterServer | Select-Object -ExpandProperty Name
                    $Properties = @(
                        'HostName'	
                        'Version'
                        'Manufacturer'
                        'Model'
                        'Cluster'
                        'PhysicalLocation'
                        'ConnectionState'
                        'Created'
                    )

                    #region Summary
                    New-PodeWebCard -Name Summary -DisplayName 'Summary of Cloud' -Content @(
                        New-PodeWebBadge -Colour Green -Value "$($VIServer.Count) vCenter"
                        $TotalCluster = $FullDB | Group-Object Cluster
                        New-PodeWebBadge -Colour Cyan -Value "$($TotalCluster.Count) Cluster"
                        $ESXiHosts = $FullDB | Group-Object HostName
                        New-PodeWebBadge -Colour Blue -Value "$($ESXiHosts.Count) ESXiHosts"
                        $FullDB | Group-Object Version | ForEach-Object {
                            switch -Regex ($_.Name){
                                '6.7'   {$Colour = 'Yellow'}
                                '7.0'   {$Colour = 'Green'}
                                default {$Colour = 'Red'}
                            }
                            New-PodeWebBadge -Colour $Colour -Value "V$($_.Name) ($($_.Count))"
                        }
                    )
                    #endregion

                    #region Search
                    New-PodeWebForm -Id "Form$($i)" -Name "Search for ESXiHost" -AsCard -ShowReset -ArgumentList @($Properties, $PodeDB, $SqlTableName) -ScriptBlock {
                        param($Properties, $PodeDB, $SqlTableName)
                        $SqliteQuery = "Select * from $($SqlTableName) Where HostName Like '%$($WebEvent.Data.Search)%'"
                        $Properties += 'vCenterServer'
                        Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery | Select-Object $Properties | Out-PodeWebTable
                    } -Content @(
                        New-PodeWebTextbox -Id "Search$($i)" -Name 'Search' -DisplayName 'HostName' -Type Text -NoForm -Width '960px' -Placeholder 'HostName'
                    )
                    #endregion

                    #region Tabs
                    New-PodeWebTabs -Tabs @(
                        foreach($item in $VIServer){
                            $i ++
                            $vCenter = (($item -split '\.')[0]).ToUpper()

                            New-PodeWebTab -Id "Tab$($i)" -Name "vCenter $($vCenter)" -Layouts @(
                                $VICluster = $FullDB | Where-Object vCenterServer -match $item | Group-Object Cluster | Select-Object -ExpandProperty Name
                                
                                #region Badge
                                New-PodeWebLine
                                New-PodeWebText -Value "vCenter «$($vCenter)» contains:" -Style Bold
                                #New-PodeWebBadge -Colour Light -Value "$($vCenter)"
                                New-PodeWebBadge -Colour Cyan -Value "$($VICluster.count) Cluster"
                                $ESXiHosts = $FullDB | Where-Object vCenterServer -match $item | Group-Object HostName
                                New-PodeWebBadge -Colour Blue -Value "$($ESXiHosts.Count) ESXiHosts"
                                New-PodeWebLine
                                #endregion

                                foreach($Cluster in $VICluster){
                                    $ii ++
        
                                    New-PodeWebTable -Id "Table$($ii)" -Name "VC$($ii)" -DisplayName "Cluster $($Cluster)" -AsCard -SimpleSort -NoExport -NoRefresh -Click -Compact -ArgumentList @($Properties, $item, $PodeDB, $SqlTableName, $Cluster) -ScriptBlock {
                                        param($Properties, $item, $PodeDB, $SqlTableName, $Cluster)
                                        $SqliteQuery = "Select * from $($SqlTableName) Where (vCenterServer Like '%$($item)%') And (Cluster = '$Cluster')"
                                        Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery | Select-Object $Properties
                                    }

                                    #region Badge
                                    New-PodeWebLine
                                    New-PodeWebText -Value "Cluster «$($Cluster)» contains:" -Style Bold
                                    #New-PodeWebBadge -Colour Light -Value "$($Cluster)"
                                    $ESXiHosts = $FullDB | Where-Object vCenterServer -match $item | Where-Object Cluster -match $Cluster | Group-Object HostName
                                    New-PodeWebBadge -Colour Blue -Value "$($ESXiHosts.Count) ESXiHosts"
                                    $FullDB | Where-Object vCenterServer -match $item | Where-Object Cluster -match $Cluster| Group-Object Version | ForEach-Object {
                                        switch -Regex ($_.Name){
                                            '6.7'   {$Colour = 'Yellow'}
                                            '7.0'   {$Colour = 'Green'}
                                            default {$Colour = 'Red'}
                                        }
                                        New-PodeWebBadge -Colour $Colour -Value "V$($_.Name) ($($_.Count))"
                                    }
                                    New-PodeWebLine
                                    #endregion
                                }
                            )
                        }
                    )
                    #endregion

                }
            }

        ) 
        
    }else{
        New-PodeWebCard -Name 'Warning' -Content @(
            New-PodeWebAlert -Value "Could not find $($PodeDB)" -Type Warning
        )
    }

    # if(Test-Path $PodeDB){
        
    #     # not in a layout
    #     if(-not([String]::IsNullOrEmpty($TableExists))){
            
    #         # not in a layout
    #         $MySQLiteDB   = Open-MySQLiteDB -Path $PodeDB
    #         if([String]::IsNullOrEmpty($MySQLiteDB)){
    #             New-PodeWebCard -Name 'Warning' -Content @(
    #                 New-PodeWebAlert -Value "Could not connect to $($PodeDB)" -Type Warning
    #             )
    #         }else{
    #             $i = 200
    #             $SqlTableName = 'cloud_ESXiHosts'
    #             $SqliteQuery  = "Select * from $($SqlTableName)"
    #             $FullDB       = Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
    #             $VIServer     = $FullDB | Group-Object vCenterServer | Select-Object -ExpandProperty Name
    #             $Properties = @(
    #                 'HostName'	
    #                 'Version'
    #                 'Manufacturer'
    #                 'Model'
    #                 'Cluster'
    #                 'PhysicalLocation'
    #                 'ConnectionState'
    #                 'Created'
    #             )

    #             #region Summary
    #             New-PodeWebCard -Name Summary -DisplayName 'Summary of Cloud' -Content @(
    #                 New-PodeWebBadge -Colour Green -Value "$($VIServer.Count) vCenter"
    #                 $TotalCluster = $FullDB | Group-Object Cluster
    #                 New-PodeWebBadge -Colour Cyan -Value "$($TotalCluster.Count) Cluster"
    #                 $ESXiHosts = $FullDB | Group-Object HostName
    #                 New-PodeWebBadge -Colour Blue -Value "$($ESXiHosts.Count) ESXiHosts"
    #                 $FullDB | Group-Object Version | ForEach-Object {
    #                     switch -Regex ($_.Name){
    #                         '6.7'   {$Colour = 'Yellow'}
    #                         '7.0'   {$Colour = 'Green'}
    #                         default {$Colour = 'Red'}
    #                     }
    #                     New-PodeWebBadge -Colour $Colour -Value "V$($_.Name) ($($_.Count))"
    #                 }
    #             )
    #             #endregion

    #             #region Search
    #             New-PodeWebForm -Id "Form$($i)" -Name "Search for ESXiHost" -AsCard -ShowReset -ArgumentList @($Properties, $PodeDB, $SqlTableName) -ScriptBlock {
    #                 param($Properties, $PodeDB, $SqlTableName)
    #                 $SqliteQuery = "Select * from $($SqlTableName) Where HostName Like '%$($WebEvent.Data.Search)%'"
    #                 $Properties += 'vCenterServer'
    #                 Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery | Select-Object $Properties | Out-PodeWebTable
    #             } -Content @(
    #                 New-PodeWebTextbox -Id "Search$($i)" -Name 'Search' -DisplayName 'HostName' -Type Text -NoForm -Width '1000px'
    #             )
    #             #endregion

    #             #region Tabs
    #             New-PodeWebTabs -Tabs @(
    #                 foreach($item in $VIServer){
    #                     $i ++
    #                     $vCenter = ($item -split '\.')[0]

    #                     New-PodeWebTab -Id "Tab$($i)" -Name "vCenter $($vCenter)" -Layouts @(
    #                         $VICluster = $FullDB | Where-Object vCenterServer -match $item | Group-Object Cluster | Select-Object -ExpandProperty Name
                            
    #                         #region Badge
    #                         New-PodeWebText -Value "vCenter:"
    #                         New-PodeWebBadge -Colour Cyan -Value "$($VICluster.count) Cluster"
    #                         $ESXiHosts = $FullDB | Where-Object vCenterServer -match $item | Group-Object HostName
    #                         New-PodeWebBadge -Colour Blue -Value "$($ESXiHosts.Count) ESXiHosts"
    #                         #endregion

    #                         foreach($Cluster in $VICluster){
    #                             $ii ++
    #                             #region Badge
    #                             New-PodeWebText -Value "Cluster:"
    #                             $ESXiHosts = $FullDB | Where-Object vCenterServer -match $item | Where-Object Cluster -match $Cluster | Group-Object HostName
    #                             New-PodeWebBadge -Colour Blue -Value "$($ESXiHosts.Count) ESXiHosts"
    #                             $FullDB | Where-Object vCenterServer -match $item | Where-Object Cluster -match $Cluster| Group-Object Version | ForEach-Object {
    #                                 switch -Regex ($_.Name){
    #                                     '6.7'   {$Colour = 'Yellow'}
    #                                     '7.0'   {$Colour = 'Green'}
    #                                     default {$Colour = 'Red'}
    #                                 }
    #                                 New-PodeWebBadge -Colour $Colour -Value "V$($_.Name) ($($_.Count))"
    #                             }
    #                             #endregion
    
    #                             New-PodeWebTable -Id $ii -Name "VC$($ii)" -DisplayName "Cluster $($Cluster)" -SimpleSort -SimpleFilter -Click -AsCard -Compact -ArgumentList @($Properties, $item, $PodeDB, $SqlTableName, $Cluster) -ScriptBlock {
    #                                 param($Properties, $item, $PodeDB, $SqlTableName, $Cluster)
    #                                 $SqliteQuery = "Select * from $($SqlTableName) Where (vCenterServer Like '%$($item)%') And (Cluster = '$Cluster')"
    #                                 Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery | Select-Object $Properties
    #                             }
    #                         }
    #                     )
    #                 }
    #             )
    #             #endregion

    #         }
    #     }else{
    #         New-PodeWebCard -Name 'Warning' -Content @(
    #             New-PodeWebAlert -Value "Could not find table in $($PodeDB)" -Type Warning
    #             New-PodeWebAlert -Value 'Please upload cloud_ESXiHost.csv and cloud_Summary.csv' -Type Important
    #         )
    #     }
    # }else{
    #     New-PodeWebCard -Name 'Warning' -Content @(
    #         New-PodeWebAlert -Value "Could not find $($PodeDB)" -Type Warning
    #     )
    # }

}