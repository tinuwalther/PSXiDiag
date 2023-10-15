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
    Invoke-MySQLiteQuery -Path $DBFile.FullName -query "ALTER TABLE $SqlTableName ADD ID [INTEGER PRIMARY KEY];"
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
$SQLite_DB | Format-Table -AutoSize

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

$SqlTableName = 'cloud_ESXiHosts'
$MySQLiteDB  = Open-MySQLiteDB -Path $DBFile.FullName
#$SqliteQuery = "Select * from $($SqlTableName) Group by vCenterServer"
$SqliteQuery = "SELECT COUNT(HostName) AS 'Total ESXiHosts' FROM $($SqlTableName) Group by vCenterServer"
$SQLite_DB   = Invoke-MySQLiteQuery -connection $MySQLiteDB -Query $SqliteQuery

foreach($item in $SQLite_DB.vCenterServer){
    $SqliteQuery  = "Select * from $($SqlTableName) Where vCenterServer Like '%$($item)%'"
    $dataset = Invoke-MySQLiteQuery -connection $MySQLiteDB -Query $SqliteQuery
    $dataset
}

$SqliteQuery = "SELECT * FROM Metadata"
$TableExists = Invoke-MySQLiteQuery -Path $DBFile.FullName -Query $SqliteQuery
$var = "Author: $($TableExists.Author), Computername: $($TableExists.Computername), Created: $($TableExists.Created), Comment: $($TableExists.Comment)"
$var



[System.IO.FileInfo]$DBFile         = 'D:\github.com\PSXiDiag\pode\db\psxi.db'
[string]$SqlTableName               = 'classic_ESXiHosts'

$db = Open-MySQLiteDB $DBFile.FullName
$SqliteQuery = "Select Created from $($SqlTableName) Limit 1"
# $SqliteQuery = "Select vCenterServer, Cluster, COUNT(HostName) AS CountOfHosts, COUNT(Cluster) AS CountOfCluster from $($SqlTableName) Group by vCenterServer"
$SQLite_DB   = Invoke-MySQLiteQuery -connection $db -Query $SqliteQuery
$SQLite_DB | Format-Table -AutoSize


#region Tests with original CSV-files
$fileWithQuotationMarks = 'D:\github.com\PSXiDiag\data\AllClassicVIServers-IXESXiHostSummary.csv'
$fileNoQuotationMarks   = 'D:\github.com\PSXiDiag\data\classic_ESXiHosts.csv'

$dbFile   = 'D:\temp\test.db'
$createDb = New-MySQLiteDB $dbFile -PassThru -force
$createDb

$csvWithQuotationMarks = Import-Csv -Delimiter ';' -Path $fileWithQuotationMarks -Encoding utf8 | Sort-Object HostName
$csvNoQuotationMarks   = Import-Csv -Delimiter ';' -Path $fileNoQuotationMarks   -Encoding utf8 | Sort-Object HostName

# $csvWithQuotationMarks | ConvertTo-Json
# $csvNoQuotationMarks   | ConvertTo-Json
# Compare-Object -ReferenceObject $csvNoQuotationMarks -DifferenceObject $csvWithQuotationMarks

# $jsonWithQuotationMarks = Get-Content -Path $fileWithQuotationMarks -
# $jsonNoQuotationMarks   = Import-Csv -Delimiter ';' -Path $fileNoQuotationMarks   -Encoding utf8 | Sort-Object HostName

# Read header from csv-file and set it as column-names to the table
$th = (Get-Content -Path $fileWithQuotationMarks   -Encoding utf8 -TotalCount 1).Split(';')
$th = (Get-Content -Path $fileNoQuotationMarks   -Encoding utf8 -TotalCount 1).Split(';')
if($th -match '"'){
    $th = (Get-Content -Path $fileWithQuotationMarks -Encoding utf8 -TotalCount 1).Split(';') -Replace '"'
}else{$false}

# ConvertTo-MySQLiteDB - works as design (no Problem)
$TableName = 'classic_ESXiHosts'
# $th = (Get-Content -Path $fileWithQuotationMarks -Encoding utf8 -TotalCount 1).Split(';')
# New-MySQLiteDBTable -Path $dbFile -TableName $TableName -ColumnNames $th -Force

$th = '"ID" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, ' + '"Created", ' 
$th = $th + (Get-Content -Path $fileWithQuotationMarks -Encoding utf8 -TotalCount 1).Replace(';',', ')
$TableExists = Invoke-MySQLiteQuery -Path $dbFile -query "SELECT * FROM sqlite_master WHERE type = 'table' AND name like '$($TableName)'"
if($TableExists){
    Invoke-MySQLiteQuery -Path $dbFile -query "DROP TABLE '$($TableName)'"
}
Invoke-MySQLiteQuery -Path $dbFile -query "CREATE TABLE '$($TableName)' ($th)"

#$csvWithQuotationMarks | ConvertTo-MySQLiteDB -Path $dbFile -TableName $TableName -Primary ID -Append
# Create table for Notes
Invoke-MySQLiteQuery -Path $dbFile -query "CREATE TABLE '$($TableName)Notes'(  
    ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, 
    HostName TEXT,
    Notes TEXT
)"

$ViewExists = Invoke-MySQLiteQuery -Path $dbFile -query "SELECT * FROM sqlite_master WHERE type = 'view' AND name like 'view_$($TableName)'"
if([string]::IsNullOrEmpty($ViewExists)){
    Invoke-MySQLiteQuery -Path $dbFile -query "CREATE VIEW 'view_$($TableName)' AS
    SELECT 
        l.'ID',
        l.'HostName', 
        l.'Version',
        l.'ConnectionState',
        l.'PhysicalLocation',
        l.'Manufacturer',
        l.'Model',
        l.'vCenterServer',
        l.'Cluster',
        l.'Created',
        n.'Notes' 
    FROM '$($TableName)' AS l
    LEFT JOIN '$($TableName)Notes' AS n
    ON l.'HostName' = n.'HostName'"
}

# import from csv
$SqlTableName = $TableName
$TableHeader  = (Get-Content -Path $fileNoQuotationMarks   -Encoding utf8 -TotalCount 1).Split(';')

$csvWithQuotationMarks | foreach-object -begin { 
    $i = 0
    $db = Open-MySQLiteDB $dbFile
} -process { 
    $i ++
    $SqlQuery = "Insert into $($SqlTableName) Values( 
        $(for($h = 0; $h -lt $TableHeader.length; $h++){ "'" + $($_.$($TableHeader[$h])) + "'" + ',' }) '$(Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff')', '$($i)'
    )"
    $SqlQuery
    Invoke-MySQLiteQuery -connection $db -keepalive -query $SqlQuery
} -end { 
    Close-MySQLiteDB $db
}


Invoke-MySQLiteQuery -Path $dbFile -query "SELECT * FROM $TableName;"
#endregion
