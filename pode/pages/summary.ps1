Add-PodeWebPage -Name 'Summary' -Title 'vCenter Summary' -Icon 'server' -ScriptBlock {

    #region module
    if(-not(Get-InstalledModule -Name mySQLite -ea SilentlyContinue)){
        Install-Module -Name mySQLite -Force
        $Error.Clear()
    }
    if(-not(Get-Module -Name mySQLite)){ Import-Module -Name mySQLite }
    #endregion

    $i = 500
    $PodeRoot = $($PSScriptRoot).Replace('pages','db')
    $PodeDB   = Join-Path $PodeRoot -ChildPath 'psxi.db'
    $SqlTableName = 'classic_summary', 'cloud_summary', 'classic_ESXiHosts', 'cloud_ESXiHost'

    if(Test-Path $PodeDB){
        $TableExists = foreach($item in $SqlTableName){
            $SqliteQuery = "SELECT * FROM sqlite_master WHERE name like '$item'"
            Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
        }
        if(-not([String]::IsNullOrEmpty($TableExists))){

            New-PodeWebCard -Name 'Overall Summary' -Content @(
                New-PodeWebText -Value "Total"
                
                $SqliteQuery = "SELECT COUNT(vCenterServer) AS 'Total vCenter', SUM(CountOfESXiHosts) AS 'Total ESXiHosts', SUM(CountOfVMs) AS 'Total VMs' FROM cloud_summary"
                $cloud_summary = Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
    
                $SqliteQuery = "SELECT COUNT(vCenterServer) AS 'Total vCenter', SUM(CountOfESXiHosts) AS 'Total ESXiHosts', SUM(CountOfVMs) AS 'Total VMs' FROM classic_summary"
                $classic_summary = Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
                
                $TotalvCenter = $classic_summary.'Total vCenter' + $cloud_summary.'Total vCenter'
                New-PodeWebBadge -Colour Green -Value "$($TotalvCenter) vCenter"
                
                $ESXiHosts = $classic_summary.'Total ESXiHosts' + $cloud_summary.'Total ESXiHosts'
                New-PodeWebBadge -Colour Blue -Value "$($ESXiHosts) ESXiHosts"
                
                $VMs = $classic_summary.'Total VMs' + $cloud_summary.'Total VMs'
                New-PodeWebBadge -Colour Light -Value "$($VMs) VMs"
            )
    
            New-PodeWebForm -Id "Form$($i)" -Name "Search for ESXiHost" -AsCard -ShowReset -ArgumentList @($PodeDB) -ScriptBlock {
                param($PodeDB)
                $SqliteQuery = "Select * from classic_ESXiHosts Where HostName Like '%$($WebEvent.Data.Search)%'"
                $Result = Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
                if([String]::IsNullOrEmpty($Result)){
                    $SqliteQuery = "Select * from cloud_ESXiHosts Where HostName Like '%$($WebEvent.Data.Search)%'"
                    $Result = Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
                }
                $Properties = @(
                    'HostName'	
                    'Version'
                    'Manufacturer'
                    'Model'
                    'Cluster'
                    'PhysicalLocation'
                    'ConnectionState'
                    'Created'
                    'vCenterServer'
                )
                $Result | Select-Object $Properties | Out-PodeWebTable
            } -Content @(
                New-PodeWebTextbox -Id "Search$($i)" -Name 'Search' -DisplayName 'HostName' -Type Text -NoForm -Width '1000px'
            )
    
            New-PodeWebGrid -Cells @(
    
                if(Test-Path $PodeDB){
                    $SqlTableName = 'classic_summary', 'cloud_summary'
                    $Properties = @(
                        'vCenterServer'	
                        'CountOfESXiHosts'
                        'CountOfVMs'
                    )
                    foreach($item in $SqlTableName){
                        $i ++
                        switch -Regex ($item){
                            'cloud'   {$DisplayName = 'Cloud'}
                            'classic' {$DisplayName = 'Classic'}
                        }
    
                        New-PodeWebCell -Width '50%' -Content @(
    
                            New-PodeWebCard -Name "$DisplayName Summary" -Content @(
                                $SqliteQuery = "SELECT COUNT(vCenterServer) AS 'Total vCenter', SUM(CountOfESXiHosts) AS 'Total ESXiHosts', SUM(CountOfVMs) AS 'Total VMs' FROM $item"
                                $summary = Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
                                New-PodeWebText -Value "Total"
                                New-PodeWebBadge -Colour Green -Value "$($summary.'Total vCenter') vCenter"
                                New-PodeWebBadge -Colour Blue -Value "$($summary.'Total ESXiHosts') ESXiHosts"
                                New-PodeWebBadge -Colour Light -Value "$($summary.'Total VMs') VMs"
                            )
    
                            # New-PodeWebTable -Id "Total$($i)" -Name "Total$($i)" -DisplayName "Total $($DisplayName)" -SimpleSort -Click -NoExport -NoRefresh -AsCard -Compact -ArgumentList @($item, $PodeDB) -ScriptBlock {
                            #     param($item, $PodeDB)
                            #     $SqliteQuery = "SELECT COUNT(vCenterServer) AS 'Total vCenter', SUM(CountOfESXiHosts) AS 'Total ESXiHosts', SUM(CountOfVMs) AS 'Total VMs'FROM $item"
                            #     Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
                            # }
    
                            New-PodeWebTable -Id "Table$($i)" -Name "Summary$($i)" -DisplayName "Summary $($DisplayName)" -SimpleSort -Click -NoExport -NoRefresh -AsCard -Compact -ArgumentList @($Properties, $item, $PodeDB) -ScriptBlock {
                                param($Properties, $item, $PodeDB)
                                $SqliteQuery = "Select * from $($item)"
                                Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery | Select-Object $Properties
                            }                     
    
                        )
                    }
                }
            )
        }else{
            New-PodeWebCard -Name 'Warning' -Content @(
                New-PodeWebAlert -Value "Could not find table in $($PodeDB)" -Type Warning
                New-PodeWebAlert -Value 'Please upload classic_ESXiHost.csv and classic_Summary.csv' -Type Important
                New-PodeWebAlert -Value 'Please upload cloud_ESXiHost.csv and cloud_Summary.csv' -Type Important
                #New-PodeWebAlert -Value 'And restart the server' -Type Important
            )
        }
    
    }else{
        New-PodeWebCard -Name 'Warning' -Content @(
            New-PodeWebAlert -Value "Could not find $($PodeDB)" -Type Warning
        )
    }

}
