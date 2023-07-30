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
    $SqlTableName = (Get-PodeConfig).PSXi.Tables

    if(Test-Path $PodeDB){

        New-PodeWebContainer -NoBackground -Content @(
            
            $PSModule = (Get-PodeConfig).PSModules
            New-PodeWebCard -Name 'Module check' -Content @(
                New-PodeWebGrid -Cells @(
                    foreach($item in $PSModule){
                        $module = (Get-Module -ListAvailable $item) | Sort-Object Version | Select-Object -Last 1
                        New-PodeWebCell -Width '50%' -Content @(
                            New-PodeWebAlert -Value "Module: $($module.Name), Version: $($module.Version)" -Type Info
                        )
                    }
                )
            )
            # New-PodeWebCard -Name 'Endpoint check' -Content @(
            #     New-PodeWebAlert -Value  $global:epurl -Type Success
            # )

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
                )
                New-PodeWebCard -Name 'Table check' -Content @(
                    $TableExists = foreach($item in $SqlTableName){
                        $SqliteQuery = "SELECT * FROM sqlite_master WHERE name like '$item'"
                        Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
                    }
                    if([String]::IsNullOrEmpty($TableExists)){
                        New-PodeWebAlert -Value "Could not find any of $($SqlTableName) in $($PodeDB)" -Type Warning
                        New-PodeWebAlert -Value "Please upload CSV-files ($($SqlTableName)) and restart the pode-server" -Type Important
                    }else{
                        New-PodeWebGrid -Cells @(

                            foreach($item in $SqlTableName){
                                New-PodeWebCell -Width '50%' -Content @(
                                    New-PodeWebAlert -Value "Table $($item)" -Type Success
                                )
                            }

                        )
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
