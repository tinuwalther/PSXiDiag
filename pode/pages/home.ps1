Set-PodeWebHomePage -Title 'Welcome to the PSXi App!' -Layouts @(

    #region module
    if(-not(Get-InstalledModule -Name mySQLite -ea SilentlyContinue)){
        Install-Module -Name mySQLite -Force
        $Error.Clear()
    }
    if(-not(Get-Module -Name mySQLite)){ Import-Module -Name mySQLite }
    #endregion

    $PodeRoot = $($PSScriptRoot).Replace('pages','db')
    $PodeDB   = Join-Path $PodeRoot -ChildPath 'psxi.db'
    $SqlTableName = (Get-PodeConfig).PSXiTables

    if(Test-Path $PodeDB){

        New-PodeWebContainer -NoBackground -Content @(

            $PSModule = (Get-PodeConfig).PSModules
            New-PodeWebCard -Name 'Module check' -Content @(
                foreach($item in $PSModule){
                    $module = (Get-Module -ListAvailable $item) | Sort-Object Version | Select-Object -Last 1
                    New-PodeWebAlert -Value "Module: $($module.Name), Version: $($module.Version)" -Type Info
                }
            )

            $SqliteQuery = "SELECT * FROM Metadata"
            $TableExists = Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
            if([String]::IsNullOrEmpty($TableExists)){
                New-PodeWebCard -Name 'Database check' -Content @(
                    New-PodeWebAlert -Value "Could not find Metadata" -Type Warning
                )
            }else{
                New-PodeWebCard -Name 'Database check' -Content @(
                    $var = "Database: Created: $($TableExists.Created), Comment: $($TableExists.Comment), $($PodeDB)"
                    New-PodeWebAlert -Value $var -Type Success

                    $TableExists = foreach($item in $SqlTableName){
                        $SqliteQuery = "SELECT * FROM sqlite_master WHERE name like '$item'"
                        Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
                    }
                    if([String]::IsNullOrEmpty($TableExists)){
                        New-PodeWebAlert -Value "Could not find any of $($SqlTableName) in $($PodeDB)" -Type Warning
                        New-PodeWebAlert -Value 'Please upload classic_ESXiHost.csv, classic_Summary.csv, cloud_ESXiHost.csv, cloud_Summary.csv and restart the pode-server' -Type Important
                    }else{
                        foreach($item in $SqlTableName){
                            New-PodeWebAlert -Value "Table $($item)" -Type Success
                        }
                    }
        
                )  
            }

        )

    }else{
        New-PodeWebCard -Name 'Database check' -Content @(
            New-PodeWebAlert -Value "Could not find $($PodeDB)" -Type Warning
        )
    }

)
