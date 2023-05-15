Add-PodeWebPage -Group 'Classic' -Name 'Classic ESXi Hosts Table' -Title 'Classic ESXi Host Inventory' -Icon 'server' -ScriptBlock {
    #region module
    if(-not(Get-InstalledModule -Name mySQLite -ea SilentlyContinue)){
        Install-Module -Name mySQLite -Force
        $Error.Clear()
    }
    if(-not(Get-Module -Name mySQLite)){ Import-Module -Name mySQLite }
    #endregion
    
    Set-PodeWebBreadcrumb -Items @(
        New-PodeWebBreadcrumbItem -Name 'Home' -Url '/'
        New-PodeWebBreadcrumbItem -Name 'Classic' -Url '/'
        New-PodeWebBreadcrumbItem -Name 'Classic ESXi Host Inventory' -Url '/pages/PageName?value=Classic ESXi Hosts Table' -Active
    )

    $PodeRoot = $($PSScriptRoot).Replace('pages','db')
    $PodeDB   = Join-Path $PodeRoot -ChildPath 'psxi.db'
    if(Test-Path $PodeDB){
        $MySQLiteDB   = Open-MySQLiteDB -Path $PodeDB
        if([String]::IsNullOrEmpty($MySQLiteDB)){
            Out-PodeWebError -Message "Could not connect to $($PodeDB)"
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

            New-PodeWebForm -Id "Form$($i)" -Name "Search for ESXiHost" -AsCard -ShowReset -ArgumentList @($Properties, $PodeDB, $SqlTableName) -ScriptBlock {
                param($Properties, $PodeDB, $SqlTableName)
                $SqliteQuery = "Select * from $($SqlTableName) Where HostName Like '%$($WebEvent.Data.Search)%'"
                $Properties += 'vCenterServer'
                Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery | Select-Object $Properties | Out-PodeWebTable
            } -Content @(
                New-PodeWebTextbox -Id "Search$($i)" -Name 'Search' -DisplayName 'HostName' -Type Text -NoForm -Width '1000px'
            )

            #New-PodeWebTabs -Tabs @(
                foreach($item in $VIServer){
                    $i ++
                    $vCenter = ($item -split '\.')[0]
                    #New-PodeWebTab -Id "Tab$($i)" -Name "vCenter $($vCenter)" -Layouts @(
                        New-PodeWebTable -Id $i -Name "VC$($i)" -DisplayName "vCenter $($vCenter)" -SimpleSort -SimpleFilter -Click -AsCard -Compact -ArgumentList @($Properties, $item, $PodeDB, $SqlTableName) -ScriptBlock {
                            param($Properties, $item, $PodeDB, $SqlTableName)
                            $SqliteQuery = "Select * from $($SqlTableName) Where vCenterServer Like '%$($item)%'"
                            Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery | Select-Object $Properties
                        }  
                    #)     
                }
            #)
        }
    }else{
        Out-PodeWebError -Message "Could not find $($PodeDB)"
    }

}
