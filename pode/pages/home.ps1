Import-PodeWebStylesheet -Url 'psxi.css'

Set-PodeWebHomePage -Title 'Welcome to the PSXi App!' -Layouts @(

    #region Defaults
    $PodeRoot = $($PSScriptRoot).Replace('pages','db')
    $PodeDB   = Join-Path $PodeRoot -ChildPath 'psxi.db'
    $SqlTableName = (Get-PodeConfig).PSXi.Tables
    $SqlViewName  = (Get-PodeConfig).PSXi.Views
    #endregion

    #region module
    if(-not(Get-InstalledModule -Name mySQLite -ea SilentlyContinue)){
        Install-Module -Name mySQLite -Force
        $Error.Clear()
    }
    if(-not(Get-Module -Name mySQLite)){ Import-Module -Name mySQLite }
    #endregion

    if(Test-Path $PodeDB){

        New-PodeWebContainer -NoBackground -Content @(
            
            #region Module check
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
            #endregion Moduel check

            #region SQLite check
            $SqliteQuery = "SELECT * FROM Metadata"
            $TableExists = Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
            if([String]::IsNullOrEmpty($TableExists)){
                New-PodeWebCard -Name 'Database check' -Content @(
                    New-PodeWebAlert -Value "Could not find Metadata" -Type Warning
                )
            }else{

                #region Database check
                New-PodeWebCard -Name 'Database check' -Content @(
                    $var = "Database: Created: $($TableExists.Created), Comment: $($TableExists.Comment), $($PodeDB)"
                    New-PodeWebAlert -Value $var -Type Success
                )
                #endregion Database check

                #region Table check
                New-PodeWebCard -Name 'Table check' -Content @(

                    $TableExists = foreach($item in $SqlTableName){
                        $SqliteQuery = "SELECT * FROM sqlite_master WHERE type = 'table' AND name like '$item'"
                        Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
                    }
                    # $TableExists | Out-Default

                    if([String]::IsNullOrEmpty($TableExists)){
                        New-PodeWebAlert -Value "Could not find any of $($SqlTableName) in $($PodeDB)" -Type Warning
                        New-PodeWebAlert -Value "Please upload CSV-files ($($SqlTableName)) and restart the pode-server" -Type Important
                    }else{
                        New-PodeWebGrid -Cells @(
                            foreach($item in $SqlTableName){
                                $TableFromMaster = Invoke-MySQLiteQuery -Path $PodeDB -Query "SELECT name FROM sqlite_master WHERE type = 'table' AND name like '$item'"
                                New-PodeWebCell -Width '50%' -Content @(
                                    if([String]::IsNullOrEmpty($($TableFromMaster.name))){
                                        New-PodeWebAlert -Value "Table $($item)" -Type Warning
                                    }else{
                                        New-PodeWebAlert -Value "Table $($TableFromMaster.name)" -Type Success
                                    }
                                )
                            }
                        )
                    }
                )
                #endregion Table check

                #region View check
                New-PodeWebCard -Name 'View check' -Content @(

                    $ViewExists = foreach($item in $SqlViewName){
                        $SqliteQuery = "SELECT * FROM sqlite_master WHERE type = 'view' AND name like '$item'"
                        Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
                    }

                    if([String]::IsNullOrEmpty($ViewExists)){
                        New-PodeWebAlert -Value "Could not find any of $($SqlViewName) in $($PodeDB)" -Type Warning
                        New-PodeWebAlert -Value "Please upload CSV-files ($($SqlViewName)) and restart the pode-server" -Type Important
                    }else{
                        New-PodeWebGrid -Cells @(
                            foreach($item in $SqlViewName){
                                $TableFromMaster = Invoke-MySQLiteQuery -Path $PodeDB -Query "SELECT name FROM sqlite_master WHERE type = 'view' AND name like '$item'"
                                New-PodeWebCell -Width '50%' -Content @(
                                    if([String]::IsNullOrEmpty($($TableFromMaster.name))){
                                        New-PodeWebAlert -Value "Table $($item)" -Type Warning
                                    }else{
                                        New-PodeWebAlert -Value "Table $($TableFromMaster.name)" -Type Success
                                    }
                                )
                            }
                        )
                    }
                )
                #endregion View check
            }
            #endregion SQLite check
        )

    }else{
        New-PodeWebCard -Name 'Database check' -Content @(
            New-PodeWebAlert -Value "Could not find $($PodeDB)" -Type Warning
        )
    }

)
