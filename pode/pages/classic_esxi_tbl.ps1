Add-PodeWebPage -Group 'Classic' -Name 'Classic ESXi Host Table' -Title 'Classic ESXi Host Inventory' -Icon 'server' -ScriptBlock {
    #region module
    if(-not(Get-InstalledModule -Name mySQLite -ea SilentlyContinue)){
        Install-Module -Name mySQLite -Force
        $Error.Clear()
    }
    if(-not(Get-Module -Name mySQLite)){ Import-Module -Name mySQLite }
    #endregion
    
    Set-PodeWebBreadcrumb -Items @(
        New-PodeWebBreadcrumbItem -Name 'Home' -Url '/'
        New-PodeWebBreadcrumbItem -Name 'Classic ESXi Host Inventory' -Url '/pages/PageName?value=Classic ESXi Hosts Table' -Active
    )

    $PodeRoot = $($PSScriptRoot).Replace('pages','db')
    $PodeDB   = Join-Path $PodeRoot -ChildPath 'psxi.db'
    $SqlTableName = 'classic_summary', 'classic_ESXiHosts'

    if(Test-Path $PodeDB){

        New-PodeWebContainer -NoBackground -Content @(

            $TableExists = foreach($item in $SqlTableName){
                $SqliteQuery = "SELECT * FROM sqlite_master WHERE name like '$item'"
                Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
            }
            if([String]::IsNullOrEmpty($TableExists)){
                New-PodeWebCard -Name 'Warning' -Content @(
                    New-PodeWebAlert -Value "Could not find table in $($PodeDB)" -Type Warning
                    New-PodeWebAlert -Value 'Please upload classic_ESXiHost.csv and classic_Summary.csv' -Type Important
                )
            }else{
                $MySQLiteDB   = Open-MySQLiteDB -Path $PodeDB
                if([String]::IsNullOrEmpty($MySQLiteDB)){
                    New-PodeWebCard -Name 'Warning' -Content @(
                        New-PodeWebAlert -Value "Could not connect to $($PodeDB)" -Type Warning
                    )
                }else{
                    $i = 100
                    $SqlTableName = 'classic_ESXiHosts'
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
                    New-PodeWebCard -Name Summary -DisplayName 'Summary of Classic' -Content @(
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
                        New-PodeWebTextbox -Id "Search$($i)" -Name 'Search' -DisplayName 'HostName' -Type Text -NoForm -Width '1000px'
                    )
                    #endregion

                    #region VIServer
                    foreach($item in $VIServer){
                        $i ++
                        $vCenter = ($item -split '\.')[0]
                        New-PodeWebCard -Name "VC$($i)" -DisplayName "vCenter $($vCenter)" -Content @(
                            $VICluster = $FullDB | Where-Object vCenterServer -match $item | Group-Object Cluster | Select-Object -ExpandProperty Name
                            
                            #region Badge
                            # New-PodeWebText -Value "$($vCenter):"
                            # New-PodeWebBadge -Colour Cyan -Value "$($VICluster.count) Cluster"
                            # $ESXiHosts = $FullDB | Where-Object vCenterServer -match $item | Group-Object HostName
                            # New-PodeWebBadge -Colour Blue -Value "$($ESXiHosts.Count) ESXiHosts"
                            #endregion
        
                            foreach($Cluster in $VICluster){
                                $ii ++
                                #region Badge
                                New-PodeWebText -Value "$($Cluster):"
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
                                #endregion

                                New-PodeWebTable -Id $ii -Name "VC$($ii)" -DisplayName "Cluster $($Cluster)" -SimpleSort -SimpleFilter -Click -Compact -NoExport -NoRefresh -ArgumentList @($Properties, $item, $PodeDB, $SqlTableName, $Cluster) -ScriptBlock {
                                    param($Properties, $item, $PodeDB, $SqlTableName, $Cluster)
                                    $SqliteQuery = "Select * from $($SqlTableName) Where (vCenterServer Like '%$($item)%') And (Cluster = '$Cluster')"
                                    Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery | Select-Object $Properties
                                }
                            }
                        ) 
                    }
                    #endregion
                }
            }

        )

    }else{
        New-PodeWebCard -Name 'Warning' -Content @(
            New-PodeWebAlert -Value "Could not find $($PodeDB)" -Type Warning
        )
    }

}
