[System.IO.FileInfo]$TempDBFile     = 'D:\github.com\PSXiDiag\pode\db\Temp.db'
[System.IO.FileInfo]$DBFile         = 'D:\github.com\PSXiDiag\pode\db\psxi.db'

[System.IO.FileInfo]$CSVFile        = 'D:\github.com\PSXiDiag\pode\input\classic_ESXiHosts.csv'
[string]$SqlTableName               = 'classic_ESXiHosts'

[System.IO.FileInfo]$CSVFile        = 'D:\github.com\PSXiDiag\pode\input\cloud_ESXiHosts.csv'
[string]$SqlTableName               = 'cloud_ESXiHosts'

#region New-SqlLiteDB
# Create new DB
if(-not(Test-Path $DBFile.FullName)){
    New-MySQLiteDB $DBFile.FullName -Comment "This is the PSXi Database" -PassThru -force
}

# Create new Table
$th = (Get-Content -Path $CSVFile.FullName -Encoding utf8 -TotalCount 1).Split(';') + 'Created'
New-MySQLiteDBTable -Path $DBFile.FullName -TableName $SqlTableName -ColumnNames $th -Force
Invoke-MySQLiteQuery -Path $DBFile.FullName -query "ALTER TABLE $SqlTableName ADD GIUD [TEXT];"
Invoke-MySQLiteQuery -Path $DBFile.FullName "Select * from $SqlTableName" | format-table
#Invoke-MySQLiteQuery -Path $DBFile.FullName -query "Pragma table_info($SqlTableName)" | Select-Object Cid,Name,Type
#endregion

#region Update-SqlLiteD
$data = Import-Csv -Delimiter ';' -Path $CSVFile.FullName -Encoding utf8
$data | foreach-object -begin { 
    $db = Open-MySQLiteDB $DBFile.FullName
} -process { 
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
        '$((New-Guid).Guid)'
    )"
    Invoke-MySQLiteQuery -connection $db -keepalive -query $SqlQuery
} -end { 
    Close-MySQLiteDB $db
}
Invoke-MySQLiteQuery -Path $DBFile.FullName "Select * from $SqlTableName" | format-table
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
        break
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
