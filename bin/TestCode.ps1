[System.IO.FileInfo]$CSVFile        = 'D:\github.com\PSXiDiag\pode\input\Inventory.csv'
[System.IO.FileInfo]$TempDBFile     = 'D:\github.com\PSXiDiag\pode\db\Temp.db'
[System.IO.FileInfo]$DBFile         = 'D:\github.com\PSXiDiag\pode\db\Inventory.db'
[string]$SqlTableName               = 'ESXHosts'

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
