#region functions

#region New-SqlLiteDB
function New-SqlLiteDB{
    param($DBFile)
    if(-not(Test-Path $DBFile.FullName)){
        New-MySQLiteDB $DBFile.FullName -Comment "This is the PSXi Database" -PassThru -force
    }
}
#endregion

#region Create new Table
function New-SQLiteTable{
    param($CSVFile, $DBFile, $SqlTableName)
    $th = (Get-Content -Path $CSVFile.FullName -Encoding utf8 -TotalCount 1).Split(';') + 'Created'
    New-MySQLiteDBTable -Path $DBFile.FullName -TableName $SqlTableName -ColumnNames $th -Force
    Invoke-MySQLiteQuery -Path $DBFile.FullName -query "ALTER TABLE $SqlTableName ADD ID [INT];"
    Invoke-MySQLiteQuery -Path $DBFile.FullName "Select * from $SqlTableName" | format-table
}
#endregion

#region Update-ESXiHosts
function Update-ESXiHostTable{
    param($CSVFile, $DBFile, $SqlTableName)
    $data = Import-Csv -Delimiter ';' -Path $CSVFile.FullName -Encoding utf8
    $data | foreach-object -begin { 
        $i = 0
        $db = Open-MySQLiteDB $DBFile.FullName
    } -process { 
        $i ++
        $SqlQuery = "Insert into $($SqlTableName) Values(
            '$($_.HostName)',
            '$($_.Version)',
            '$($_.Manufacturer)',
            '$($_.Model)',
            '$($_.vCenterServer)',
            '$($_.Cluster)',
            '$($_.PhysicalLocation)',
            '$($_.ConnectionState)',
            '$(Get-Date)',
            '$($i)'
        )"
        Invoke-MySQLiteQuery -connection $db -keepalive -query $SqlQuery
    } -end { 
        Close-MySQLiteDB $db
    }
    Invoke-MySQLiteQuery -Path $DBFile.FullName "Select * from $SqlTableName" | format-table
}
#endregion

#region Update-Summary
function Update-SummaryTable{
    param($CSVFile, $DBFile, $SqlTableName)
    $data = Import-Csv -Delimiter ';' -Path $CSVFile.FullName -Encoding utf8
    $data | foreach-object -begin { 
        $i = 0
        $db = Open-MySQLiteDB $DBFile.FullName
    } -process { 
        $i ++
        $SqlQuery = "Insert into $($SqlTableName) Values(
            '$($_.vCenterServer)',
            '$($_.CountOfESXiHosts)',
            '$($_.CountOfVMs)',
            '$(Get-Date)',
            '$($i)'
        )"
        Invoke-MySQLiteQuery -connection $db -keepalive -query $SqlQuery
    } -end { 
        Close-MySQLiteDB $db
    }
    Invoke-MySQLiteQuery -Path $DBFile.FullName "Select * from $SqlTableName" | format-table
}
#endregion

#endregion

[System.IO.FileInfo]$TempDBFile     = 'D:\github.com\PSXiDiag\pode\db\Temp.db'
[System.IO.FileInfo]$DBFile         = 'D:\github.com\PSXiDiag\pode\db\psxi.db'

New-SqlLiteDB -DBFile $DBFile 

#region Classic
[System.IO.FileInfo]$CSVFile        = 'D:\github.com\PSXiDiag\pode\input\classic_ESXiHosts.csv'
[string]$SqlTableName               = 'classic_ESXiHosts'

New-SQLiteTable -CSVFile $CSVFile -DBFile $DBFile -SqlTableName $SqlTableName
Update-ESXiHostTable -CSVFile $CSVFile -DBFile $DBFile -SqlTableName $SqlTableName

[System.IO.FileInfo]$CSVFile        = 'D:\github.com\PSXiDiag\pode\input\classic_summary.csv'
[string]$SqlTableName               = 'classic_summary'

New-SQLiteTable -CSVFile $CSVFile -DBFile $DBFile -SqlTableName $SqlTableName
Update-SummaryTable -CSVFile $CSVFile -DBFile $DBFile -SqlTableName $SqlTableName
#endregion

#region Cloud
[System.IO.FileInfo]$CSVFile        = 'D:\github.com\PSXiDiag\pode\input\cloud_ESXiHosts.csv'
[string]$SqlTableName               = 'cloud_ESXiHosts'

New-SQLiteTable -CSVFile $CSVFile -DBFile $DBFile -SqlTableName $SqlTableName
Update-ESXiHostTable -CSVFile $CSVFile -DBFile $DBFile -SqlTableName $SqlTableName

[System.IO.FileInfo]$CSVFile        = 'D:\github.com\PSXiDiag\pode\input\cloud_summary.csv'
[string]$SqlTableName               = 'cloud_summary'

New-SQLiteTable -CSVFile $CSVFile -DBFile $DBFile -SqlTableName $SqlTableName
Update-SummaryTable -CSVFile $CSVFile -DBFile $DBFile -SqlTableName $SqlTableName
#endregion


$db = Open-MySQLiteDB $DBFile.FullName
$SqliteQuery = "Select vCenterServer from $($SqlTableName) Group by vCenterServer"
$SQLite_DB   = Invoke-MySQLiteQuery -connection $db -Query $SqliteQuery
$SQLite_DB | ft -AutoSize

$db = Open-MySQLiteDB $DBFile.FullName
$SqliteQuery = "Select * from $($SqlTableName)"
$FullDB      = Invoke-MySQLiteQuery -connection $db -Query $SqliteQuery
$vCenterServer = $FullDB | Group-Object vCenterServer | Select-Object -ExpandProperty Name
foreach($item in $vCenterServer){
    if($FullDB.vCenterServer -like $item){
        $FullDB
    }
}

# Create TempDB
$SqlTypeName  = 'psxi'    
$data = Import-Csv -Delimiter ';' -Path $CSVFile.FullName -Encoding utf8 | Sort-Object HostName
$data | Add-Member NoteProperty Created $((Get-Date (Get-Date).AddDays(-5)))
$data | ConvertTo-MySQLiteDB -Path $TempDBFile -TableName $SqlTableName -TypeName $SqlTypeName -Force -Primary HostName

$data | ConvertTo-MySQLiteDB -Path $DBFile -TableName $SqlTableName -TypeName $SqlTypeName -Force -Primary HostName


# Get data from temp-table
$MySQLiteDB  = Open-MySQLiteDB -Path $TempDBFile.FullName
$SqliteQuery = "Select * from $($SqlTableName) order by HostName"
$Temp_DB     = Invoke-MySQLiteQuery -connection $MySQLiteDB -Query $SqliteQuery
$Temp_DB.Count

# Get data from table
$MySQLiteDB  = Open-MySQLiteDB -Path $DBFile.FullName
$SqliteQuery = "Select * from $($SqlTableName) Group by vCenterServer"
$SQLite_DB   = Invoke-MySQLiteQuery -connection $MySQLiteDB -Query $SqliteQuery
$SQLite_DB.vCenterServer

foreach($item in $SQLite_DB.vCenterServer){
    $MySQLiteDB  = Open-MySQLiteDB -Path $DBFile.FullName
    $SqliteQuery = "Select * from $($SqlTableName) Order by HostName"
    $SQLite_DB   = Invoke-MySQLiteQuery -connection $MySQLiteDB -Query $SqliteQuery

}

$SqlTableName = 'ESXHosts'
$MySQLiteDB  = Open-MySQLiteDB -Path $DBFile.FullName
$SqliteQuery = "Select * from $($SqlTableName) Group by vCenterServer"
$SQLite_DB   = Invoke-MySQLiteQuery -connection $MySQLiteDB -Query $SqliteQuery
foreach($item in $SQLite_DB.vCenterServer){
    $SqliteQuery  = "Select * from $($SqlTableName) Where vCenterServer Like '%$($item)%'"
    $dataset = Invoke-MySQLiteQuery -connection $MySQLiteDB -Query $SqliteQuery
    $dataset
}
