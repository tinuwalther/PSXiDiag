Add-PodeWebPage -Group 'Cloud' -Name 'Cloud ESXi Hosts Table' -Title 'Cloud ESXi Host Inventory' -Icon 'server' -ScriptBlock {
    #region module
    if(-not(Get-InstalledModule -Name mySQLite -ea SilentlyContinue)){
        Install-Module -Name mySQLite -Force
        $Error.Clear()
    }
    if(-not(Get-Module -Name mySQLite)){ Import-Module -Name mySQLite }
    #endregion

    Set-PodeWebBreadcrumb -Items @(
        New-PodeWebBreadcrumbItem -Name 'Home' -Url '/'
        New-PodeWebBreadcrumbItem -Name 'Cloud' -Url '/'
        New-PodeWebBreadcrumbItem -Name 'Cloud ESXi Host Inventory' -Url '/pages/PageName?value=Cloud ESXi Hosts Table' -Active
    )
    
    $PodeRoot = $($PSScriptRoot).Replace('pages','db')
    $PodeDB   = Join-Path $PodeRoot -ChildPath 'psxi.db'
    if(Test-Path $PodeDB){
        $MySQLiteDB   = Open-MySQLiteDB -Path $PodeDB
        if([String]::IsNullOrEmpty($MySQLiteDB)){
            Out-PodeWebError -Message "Could not connect to $($PodeDB)"
        }else{
            $i = 200
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

            New-PodeWebCard -Name Summary -DisplayName 'Summary of Cloud' -Content @(
                New-PodeWebText -Value "Total vCenter $($VIServer.count), "
                $FullDB | Group-Object Version | ForEach-Object {
                    $Value = "Version $($_.Name) = $($_.Count), "
                    New-PodeWebText -Value $Value.TrimEnd(', ')
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

            New-PodeWebTabs -Tabs @(
                foreach($item in $VIServer){
                    $i ++
                    $vCenter = ($item -split '\.')[0]
                    New-PodeWebTab -Id "Tab$($i)" -Name "vCenter $($vCenter)" -Layouts @(
                        New-PodeWebTable -Id $i -Name "VC$($i)" -DisplayName "vCenter $($vCenter)" -SimpleSort -SimpleFilter -Click -AsCard -Compact -ArgumentList @($Properties, $item, $PodeDB, $SqlTableName) -ScriptBlock {
                            param($Properties, $item, $PodeDB, $SqlTableName)
                            $SqliteQuery = "Select * from $($SqlTableName) Where vCenterServer Like '%$($item)%'"
                            Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery | Select-Object $Properties
                        }       
                    )
                }
            )

        }
    }else{
        Out-PodeWebError -Message "Could not find $($PodeDB)"
    }

}
