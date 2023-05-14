Set-PodeWebHomePage -Title 'Welcome to the PSXi App!' -Layouts @(

    New-PodeWebGrid -Cells @(

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

                    # $SqliteQuery = "SELECT COUNT(vCenterServer) AS 'Total vCenter', SUM(CountOfESXiHosts) AS 'Total ESXiHosts', SUM(CountOfVMs) AS 'Total VMs'FROM $item"
                    # $ret = Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
                    # New-PodeWebBadge -Colour Green -Value $ret.'Total vCenter'
                    # New-PodeWebBadge -Colour Green -Value $ret.'Total ESXiHosts'
                    # New-PodeWebBadge -Colour Green -Value $ret.'Total VMs'

                    New-PodeWebTable -Id "Total$($i)" -Name "Total$($i)" -DisplayName "Total $($DisplayName)" -SimpleSort -Click -NoExport -NoRefresh -AsCard -Compact -ArgumentList @($item, $PodeDB) -ScriptBlock {
                        param($item, $PodeDB)
                        $SqliteQuery = "SELECT COUNT(vCenterServer) AS 'Total vCenter', SUM(CountOfESXiHosts) AS 'Total ESXiHosts', SUM(CountOfVMs) AS 'Total VMs'FROM $item"
                        Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
                    }

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
