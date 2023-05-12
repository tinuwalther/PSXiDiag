Add-PodeWebPage -Group 'Cloud' -Name 'ESXi Inventory' -Title 'ESXi Inventory' -Icon 'server' -ScriptBlock {
    #region module
    if(-not(Get-InstalledModule -Name mySQLite -ea SilentlyContinue)){
        Install-Module -Name mySQLite -Force
        $Error.Clear()
    }
    if(-not(Get-Module -Name mySQLite)){ Import-Module -Name mySQLite }
    #endregion
    
    $PodeRoot = $($PSScriptRoot).Replace('pages','db')
    $PodeDB   = Join-Path $PodeRoot -ChildPath 'Inventory.db'
    if(Test-Path $PodeDB){
        $MySQLiteDB   = Open-MySQLiteDB -Path $PodeDB
        if([String]::IsNullOrEmpty($MySQLiteDB)){
            Out-PodeWebError -Message "Could not connect to $($PodeDB)"
        }else{
            $SqlTableName = 'ESXHosts'
            $MySQLiteDB  = Open-MySQLiteDB -Path $PodeDB
            $SqliteQuery = "Select * from $($SqlTableName) Group by vCenterServer"
            $SQLite_DB   = Invoke-MySQLiteQuery -connection $MySQLiteDB -Query $SqliteQuery
            foreach($item in $SQLite_DB.vCenterServer){
                $i ++
                $vCenter = ($item -split '\.')[0]
                New-PodeWebTable -Id $i -Name "VC$($i)" -DisplayName "vCenter $($vCenter)" -SimpleSort -SimpleFilter -Click -AsCard -Compact -ArgumentList @($item, $PodeDB, $SqlTableName) -ScriptBlock {
                    param($item, $PodeDB, $SqlTableName)
                    $MySQLiteDB  = Open-MySQLiteDB -Path $PodeDB
                    $SqliteQuery = "Select * from $($SqlTableName) Where vCenterServer Like '%$($item)%'"
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
                    Invoke-MySQLiteQuery -connection $MySQLiteDB -Query $SqliteQuery | Select-Object $Properties
                }            
            }
        }
    }else{
        Out-PodeWebError -Message "Could not find $($PodeDB)"
    }

}
