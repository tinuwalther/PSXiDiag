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
    $SqlTableName = 'classic_summary', 'cloud_summary', 'classic_ESXiHosts', 'cloud_ESXiHost'

    if(Test-Path $PodeDB){

        New-PodeWebContainer -NoBackground -Content @(

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
                        New-PodeWebAlert -Value "Could not find table in $($PodeDB)" -Type Warning
                        New-PodeWebAlert -Value 'Please upload classic_ESXiHost.csv and classic_Summary.csv' -Type Important
                        New-PodeWebAlert -Value 'Please upload cloud_ESXiHost.csv and cloud_Summary.csv' -Type Important
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
