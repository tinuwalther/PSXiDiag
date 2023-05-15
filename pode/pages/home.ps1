Set-PodeWebHomePage -Title 'Welcome to the PSXi App!' -Layouts @(

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

    New-PodeWebCard -Name 'Overall Summary' -Content @(
        New-PodeWebText -Value "Total"
        $SqliteQuery = "SELECT COUNT(vCenterServer) AS 'Total vCenter', SUM(CountOfESXiHosts) AS 'Total ESXiHosts', SUM(CountOfVMs) AS 'Total VMs' FROM classic_summary"
        $classic_summary = Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
        
        $SqliteQuery = "SELECT COUNT(vCenterServer) AS 'Total vCenter', SUM(CountOfESXiHosts) AS 'Total ESXiHosts', SUM(CountOfVMs) AS 'Total VMs' FROM cloud_summary"
        $cloud_summary = Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
        
        $TotalvCenter = $classic_summary.'Total vCenter' + $cloud_summary.'Total vCenter'
        New-PodeWebBadge -Colour Green -Value "$($TotalvCenter) vCenter"
        
        $ESXiHosts = $classic_summary.'Total ESXiHosts' + $cloud_summary.'Total ESXiHosts'
        New-PodeWebBadge -Colour Blue -Value "$($ESXiHosts) ESXiHosts"
        
        $VMs = $classic_summary.'Total VMs' + $cloud_summary.'Total VMs'
        New-PodeWebBadge -Colour Light -Value "$($VMs) VMs"
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
                        $classic_summary = Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
                        New-PodeWebText -Value "Total"
                        New-PodeWebBadge -Colour Green -Value "$($classic_summary.'Total vCenter') vCenter"
                        New-PodeWebBadge -Colour Blue -Value "$($classic_summary.'Total ESXiHosts') ESXiHosts"
                        New-PodeWebBadge -Colour Light -Value "$($classic_summary.'Total VMs') VMs"
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

)
