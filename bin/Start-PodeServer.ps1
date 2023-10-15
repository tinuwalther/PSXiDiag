#Requires -Modules PsNetTools, PSHTML, Pode, Pode.Web, mySQLite
<#
.SYNOPSIS
    Start Pode server

.DESCRIPTION
    Test if it's running on Windows, then test if it's running with elevated Privileges, and start a new session if not.

.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.

.EXAMPLE
    Start-PodeServer.ps1 -Verbose
#>
[CmdletBinding()]
param ()

#region functions
function Test-IsElevated {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [OSType]$OS
    )

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')
    if($OS -eq [OSType]::Windows){
        $user = [Security.Principal.WindowsIdentity]::GetCurrent()
        $ret  = (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    }elseif($OS -eq [OSType]::Mac){
        $ret = ((id -u) -eq 0)
    }

    Write-Verbose $ret
    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')
    return $ret
}

function Set-HostEntry{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String] $Name,

        [Parameter(Mandatory=$false)]
        [Switch]$Elevated
    )

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')

    $PsNetHostsTable = Get-PsNetHostsTable
    if($PsNetHostsTable.ComputerName -contains $Name){
        $ret = $true
    }else{
        if($Elevated) {
            Write-Host "Try to add $($Name) to hosts-file" -ForegroundColor Green
            Add-PsNetHostsEntry -IPAddress 127.0.0.1 -Hostname $($Name) -FullyQualifiedName "$($Name).local"
        }else{
            Write-Host "Try to add $($Name) to hosts-file need elevated Privileges" -ForegroundColor Yellow
            $ret = $false
        }
    }
    Write-Verbose $(($PsNetHostsTable | Where-Object ComputerName -match $($Name)) | Out-String)

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')

    return $ret
}

function Set-PodeRoutes {
    [CmdletBinding()]
    param()

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')

    Add-PodeRoute -Method Get -Path '/classic_ESXiHosts_diag' -ScriptBlock {
        Write-PodeViewResponse -Path 'Classic-ESXiHost-Diagram'
    }

    Add-PodeRoute -Method Get -Path '/cloud_ESXiHosts_diag' -ScriptBlock {
        Write-PodeViewResponse -Path 'Cloud-ESXiHost-Diagram'
    }

    # Add Navbar
    $navDropdown = New-PodeWebNavDropdown -Name 'github' -Icon 'github' -Items @(
        New-PodeWebNavLink -Name 'Badgerati' -Url 'https://github.com/Badgerati/Pode.Web' -Icon 'github' -NewTab
        New-PodeWebNavLink -Name 'tinuwalther' -Url 'https://github.com/tinuwalther' -Icon 'github' -NewTab
    )
    $navDiv = New-PodeWebNavDivider
    $navPodeWeb = New-PodeWebNavLink -Name 'Pode.Web' -Url 'https://badgerati.github.io/Pode.Web' -Icon 'help-circle-outline' -NewTab
    Set-PodeWebNavDefault -Items $navDropdown, $navDiv, $navPodeWeb

    # Add dynamic pages
    $PodeRoot = $($PSScriptRoot).Replace('bin','pode')
    foreach($item in (Get-ChildItem -Filter '*.ps1' -Path (Join-Path $PodeRoot -ChildPath 'pages'))){
        . "$($item.FullName)"
    }
    $ep = Add-PodeEndpoint -Address * -Port 5989 -Protocol Http -Hostname 'psxi' -PassThru
    foreach($item in $ep.keys){
        if($item -eq 'Url'){
            $global:epurl = $ep[$item]
        }
    }
    

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')

}

function Invoke-FileWatcher{
    <#
        Returns:
        - Changed
        - classic_ESXiHosts.csv
        - D:\github.com\PSXiDiag\pode\upload\classic_ESXiHosts.csv
        #>
    [CmdletBinding()]
    param()

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')

    $WatchFolder = Join-Path $($PSScriptRoot).Replace('bin','pode') -ChildPath 'upload'

    Add-PodeFileWatcher -EventName Changed -Path $WatchFolder -ScriptBlock {
        # file name and path
        Write-Verbose "$($FileEvent.Name) -> $($FileEvent.Type) -> $($FileEvent.FullPath)" #| Out-Default

        switch($FileEvent.Type){
            'Changed' {
                # Test if the extension is csv
                if($FileEvent.Name -match '\.csv'){
                    $DBRoot       = Join-Path $($PSScriptRoot).Replace('bin','pode') -ChildPath 'db'
                    $DBFullPath   = Join-Path $DBRoot -ChildPath 'psxi.db'
                    $TableName    = ($FileEvent.Name) -replace '.csv'
                    if(Test-Path $DBFullPath){
                        if((Get-PodeConfig).DebugLevel -eq 'Info'){
                            "Database-Check: Database $DBFullPath already exists" | Out-PodeHost
                        }

                        # Read header from csv-file and set it as column-names to the table
                        $th = (Get-Content -Path $FileEvent.FullPath -Encoding utf8 -TotalCount 1).Split(';')
                        if((Get-PodeConfig).DebugLevel -eq 'Info'){
                            "Table header: $($th)" | Out-Default
                            "Table-Check: Ovewrite the Table $($TableName) if its already exists" | Out-PodeHost
                        }

                        # Create new empty table, replace if it exists
                        New-MySQLiteDBTable -Path $DBFullPath -TableName $TableName -ColumnNames @($th + 'Created') -Force
                        $th = $null
                        
                        # Add ID as primary-key th the table
                        Invoke-MySQLiteQuery -Path $DBFullPath -query "ALTER TABLE $TableName ADD ID [INTEGER PRIMARY KEY];"
                        
                        switch -Regex ($TableName){
                            '_ESXiHosts$' {
                                if((Get-PodeConfig).DebugLevel -eq 'Info'){
                                    "Item received: $($FileEvent.FullPath)" | Out-PodeHost
                                    "Table-Check: Add content 'ESXiHost' to the table $TableName" | Out-PodeHost
                                }

                                $theader = (Get-Content -Path $FileEvent.FullPath -Encoding utf8 -TotalCount 1).Split(';')
                                if($theader -match '"'){
                                    $theader = (Get-Content -Path $FileEvent.FullPath -Encoding utf8 -TotalCount 1).Split(';') -Replace '"'
                                }
                        
                                # Create table for Notes
                                $TableExists = Invoke-MySQLiteQuery -Path $DBFullPath -query "SELECT * FROM sqlite_master WHERE type = 'table' AND name like '$($TableName)Notes'"
                                if([string]::IsNullOrEmpty($TableExists)){
                                    Invoke-MySQLiteQuery -Path $DBFullPath -query "CREATE TABLE '$($TableName)Notes'(  
                                        ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, 
                                        HostName TEXT,
                                        Notes TEXT
                                    )"
                                }

                                # Create views
                                $ViewExists = Invoke-MySQLiteQuery -Path $DBFullPath -query "SELECT * FROM sqlite_master WHERE type = 'view' AND name like 'view_$($TableName)'"
                                if([string]::IsNullOrEmpty($ViewExists)){
                                    Invoke-MySQLiteQuery -Path $DBFullPath -query "CREATE VIEW 'view_$($TableName)' AS
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

                                Update-ESXiHostTable -CSVFile $FileEvent.FullPath -DBFile $DBFullPath -SqlTableName $TableName -TableHeader $theader
                                Invoke-PshtmlESXiDiagram -DBFile $($DBFullPath) -ScriptFile $(Join-Path $PSScriptRoot -ChildPath "New-PshtmlESXiDiag.ps1") -SqlTableName $TableName
                                if((Get-PodeConfig).DebugLevel -eq 'Info'){
                                    "Remove item: $($FileEvent.FullPath)" | Out-PodeHost
                                }
                                Remove-Item -Path $FileEvent.FullPath -Force
                                $theader = $null
                            }

                            '_Datastores$' {
                                if((Get-PodeConfig).DebugLevel -eq 'Info'){
                                    "Item received: $($FileEvent.FullPath)" | Out-PodeHost
                                    "Table-Check: Add content 'Datastores' to the table $TableName" | Out-PodeHost
                                }

                                $theader = (Get-Content -Path $FileEvent.FullPath -Encoding utf8 -TotalCount 1).Split(';')
                                if($theader -match '"'){
                                    $theader = (Get-Content -Path $FileEvent.FullPath -Encoding utf8 -TotalCount 1).Split(';') -Replace '"'
                                }

                                Update-DatastoreTable -CSVFile $FileEvent.FullPath -DBFile $DBFullPath -SqlTableName $TableName -TableHeader $theader
                                if((Get-PodeConfig).DebugLevel -eq 'Info'){
                                    "Remove item: $($FileEvent.FullPath)" | Out-PodeHost
                                }
                                Remove-Item -Path $FileEvent.FullPath -Force
                                $theader = $null
                            }

                            '_Networks$' {
                                if((Get-PodeConfig).DebugLevel -eq 'Info'){
                                    "Item received: $($FileEvent.FullPath)" | Out-PodeHost
                                    "Table-Check: Add content 'Networks' to the table $TableName" | Out-PodeHost
                                }

                                $theader = (Get-Content -Path $FileEvent.FullPath -Encoding utf8 -TotalCount 1).Split(';')
                                if($theader -match '"'){
                                    $theader = (Get-Content -Path $FileEvent.FullPath -Encoding utf8 -TotalCount 1).Split(';') -Replace '"'
                                }

                                Update-NetworkTable -CSVFile $FileEvent.FullPath -DBFile $DBFullPath -SqlTableName $TableName -TableHeader $theader
                                if((Get-PodeConfig).DebugLevel -eq 'Info'){
                                    "Remove item: $($FileEvent.FullPath)" | Out-PodeHost
                                }
                                Remove-Item -Path $FileEvent.FullPath -Force
                                $theader = $null
                            }

                            '_summary$' {
                                if((Get-PodeConfig).DebugLevel -eq 'Info'){
                                    "Item received: $($FileEvent.FullPath)" | Out-PodeHost
                                    "Table-Check: Add content 'Summary' to the table $TableName" | Out-PodeHost
                                }
                                Update-SummaryTable -CSVFile $FileEvent.FullPath -DBFile $DBFullPath -SqlTableName $TableName
                                if((Get-PodeConfig).DebugLevel -eq 'Info'){
                                    "Remove item: $($FileEvent.FullPath)" | Out-PodeHost
                                }
                                Remove-Item -Path $FileEvent.FullPath -Force
                            }
                        }

                    }else{
                        "$DBFullPath not available" | Out-PodeHost
                    }
                }
            }
            default {
                $FileEvent.Type | Out-PodeHost
            }
        }
    }
    
    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')
}

function Update-ESXiHostTable{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({ if(Test-Path -Path $($_) ){$true}else{Throw "File '$($_)' not found"} })]
        [System.IO.FileInfo]$DBFile,

        [Parameter(Mandatory=$true)]
        [ValidateScript({ if(Test-Path -Path $($_) ){$true}else{Throw "File '$($_)' not found"} })]
        [System.IO.FileInfo]$CSVFile,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Object]$TableHeader,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SqlTableName
    )

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')

    # There is a problem, if the data in the csv has ""
    $data = Import-Csv -Delimiter ';' -Path $CSVFile.FullName -Encoding utf8
    $data | foreach-object -begin { 
        $i = 0
        $db = Open-MySQLiteDB $DBFile.FullName
    } -process { 
        $i ++
        $SqlQuery = "Insert into $($SqlTableName) Values( 
            $(for($h = 0; $h -lt $TableHeader.length; $h++){ "'" + $($_.$($TableHeader[$h])) + "'" + ',' }) '$(Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff')', '$($i)'
        )"
        # $(for($h = 0; $h -lt $TableHeader.length; $h++){ "'" + $($_.$($TableHeader[$h])) + "'" + ',' }) '$(Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff')', '$($i)'
        # Same as hardcoded version:
        # $SqlQuery = "Insert into $($SqlTableName) Values(
        #     '$($_.HostName)', '$($_.Version)', '$($_.Manufacturer)', '$($_.Model)', '$($_.vCenterServer)',
        #     '$($_.Cluster)', '$($_.PhysicalLocation)', '$($_.ConnectionState)', '$($_.Notes)', '$(Get-Date)', '$($i)'
        # )"
        if((Get-PodeConfig).DebugLevel -eq 'Info'){
            $SqlQuery | Out-Default
        }
        Invoke-MySQLiteQuery -connection $db -keepalive -query $SqlQuery
    } -end { 
        Close-MySQLiteDB $db
    }

    #region add or merge Notes, Master is the Notes-Table
    $ESXiHosts = Invoke-MySQLiteQuery -Path $DBFile.FullName -Query "SELECT HostName, Notes FROM '$($SqlTableName)' WHERE Notes >''"
    foreach($esxi in $ESXiHosts){
        if((Get-PodeConfig).DebugLevel -eq 'Info'){
            "$($SqlTableName): found Notes for $($esxi.HostName) = $($esxi.Notes)" | Out-Default
        }
        $ESXiHostsNotes = Invoke-MySQLiteQuery -Path $DBFile.FullName -Query "SELECT HostName, Notes FROM '$($SqlTableName)Notes' WHERE HostName = '$($esxi.HostName)'"
        if([String]::IsNullOrEmpty($ESXiHostsNotes)){
            if((Get-PodeConfig).DebugLevel -eq 'Info'){
                "$($SqlTableName)Notes: no Notes for $($esxi.HostName), insert into" | Out-Default
            }
            $InsertNotes = $($esxi.Notes).Trim()
            # No Notes found, insert into table
            $SqliteQuery = "INSERT INTO '$($SqlTableName)Notes' (HostName, Notes) VALUES ('$($esxi.HostName)', '$($InsertNotes)')"
            Invoke-MySQLiteQuery -Path $DBFile.FullName -Query $SqliteQuery
        }else{
            # Notes found for one or more Hosts
            foreach($item in $ESXiHostsNotes){
                if((Get-PodeConfig).DebugLevel -eq 'Info'){
                    "$($SqlTableName)Notes: found Notes for $($item.HostName) = $($item.Notes), update" | Out-Default
                }
                if($($item.Notes) -match $($esxi.Notes)){
                    $MergedNotes = $($item.Notes).Trim()
                }else{
                    $MergedNotes = $("$($item.Notes), from CSV: $($esxi.Notes)").Trim()
                }
                # Notes found, update table
                $SqliteQuery = "UPDATE '$($SqlTableName)Notes' SET Notes='$($MergedNotes)' WHERE HostName = '$($esxi.HostName)'"
                Invoke-MySQLiteQuery -Path $DBFile.FullName -Query $SqliteQuery
            }
        }
    }
    #endregion add or merge Notes

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')
}

function Update-DatastoreTable{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({ if(Test-Path -Path $($_) ){$true}else{Throw "File '$($_)' not found"} })]
        [System.IO.FileInfo]$DBFile,

        [Parameter(Mandatory=$true)]
        [ValidateScript({ if(Test-Path -Path $($_) ){$true}else{Throw "File '$($_)' not found"} })]
        [System.IO.FileInfo]$CSVFile,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Object]$TableHeader,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SqlTableName
    )

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')

    # There is a problem, if the data in the csv has ""
    $data = Import-Csv -Delimiter ';' -Path $CSVFile.FullName -Encoding utf8
    $data | foreach-object -begin { 
        $i = 0
        $db = Open-MySQLiteDB $DBFile.FullName
    } -process { 
        $i ++
        $SqlQuery = "Insert into $($SqlTableName) Values( 
            $(for($h = 0; $h -lt $TableHeader.length; $h++){ "'" + $($_.$($TableHeader[$h])) + "'" + ',' }) '$(Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff')', '$($i)'
        )"
        # $(for($h = 0; $h -lt $TableHeader.length; $h++){ "'" + $($_.$($TableHeader[$h])) + "'" + ',' }) '$(Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff')', '$($i)'
        # Same as hardcoded version:
        # $SqlQuery = "Insert into $($SqlTableName) Values(
        #     '$($_.HostName)', '$($_.Version)', '$($_.Manufacturer)', '$($_.Model)', '$($_.vCenterServer)',
        #     '$($_.Cluster)', '$($_.PhysicalLocation)', '$($_.ConnectionState)', '$($_.Notes)', '$(Get-Date)', '$($i)'
        # )"
        if((Get-PodeConfig).DebugLevel -eq 'Info'){
            $SqlQuery | Out-Default
        }
        Invoke-MySQLiteQuery -connection $db -keepalive -query $SqlQuery
    } -end { 
        Close-MySQLiteDB $db
    }

    #region add or merge Notes, Master is the Notes-Table
    #endregion add or merge Notes

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')
}

function Update-NetworkTable{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({ if(Test-Path -Path $($_) ){$true}else{Throw "File '$($_)' not found"} })]
        [System.IO.FileInfo]$DBFile,

        [Parameter(Mandatory=$true)]
        [ValidateScript({ if(Test-Path -Path $($_) ){$true}else{Throw "File '$($_)' not found"} })]
        [System.IO.FileInfo]$CSVFile,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Object]$TableHeader,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SqlTableName
    )

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')

    # There is a problem, if the data in the csv has ""
    $data = Import-Csv -Delimiter ';' -Path $CSVFile.FullName -Encoding utf8
    $data | foreach-object -begin { 
        $i = 0
        $db = Open-MySQLiteDB $DBFile.FullName
    } -process { 
        $i ++
        $SqlQuery = "Insert into $($SqlTableName) Values( 
            $(for($h = 0; $h -lt $TableHeader.length; $h++){ "'" + $($_.$($TableHeader[$h])) + "'" + ',' }) '$(Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff')', '$($i)'
        )"
        # $(for($h = 0; $h -lt $TableHeader.length; $h++){ "'" + $($_.$($TableHeader[$h])) + "'" + ',' }) '$(Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff')', '$($i)'
        # Same as hardcoded version:
        # $SqlQuery = "Insert into $($SqlTableName) Values(
        #     '$($_.HostName)', '$($_.Version)', '$($_.Manufacturer)', '$($_.Model)', '$($_.vCenterServer)',
        #     '$($_.Cluster)', '$($_.PhysicalLocation)', '$($_.ConnectionState)', '$($_.Notes)', '$(Get-Date)', '$($i)'
        # )"
        if((Get-PodeConfig).DebugLevel -eq 'Info'){
            $SqlQuery | Out-Default
        }
        Invoke-MySQLiteQuery -connection $db -keepalive -query $SqlQuery
    } -end { 
        Close-MySQLiteDB $db
    }

    #region add or merge Notes, Master is the Notes-Table
    #endregion add or merge Notes

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')
}

function Update-SummaryTable{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({ if(Test-Path -Path $($_) ){$true}else{Throw "File '$($_)' not found"} })]
        [System.IO.FileInfo]$DBFile,

        [Parameter(Mandatory=$true)]
        [ValidateScript({ if(Test-Path -Path $($_) ){$true}else{Throw "File '$($_)' not found"} })]
        [System.IO.FileInfo]$CSVFile,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SqlTableName
    )

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')
    $data = Import-Csv -Delimiter ';' -Path $CSVFile.FullName -Encoding utf8
    Write-Verbose "($data | Select-Object -First 1 | Format-Table | Out-String)"
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
    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')
}

function New-SqlLiteDB{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]$DBFile
    )

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')
    if(-not(Test-Path $DBFile.FullName)){
        Write-Verbose "Create new database $($DBFile.BaseName)" #| Out-Default
        New-MySQLiteDB $DBFile.FullName -Comment "This is the PSXi Database" -PassThru -force
    }
    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')
}

function Invoke-PshtmlESXiDiagram{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({ if(Test-Path -Path $($_) ){$true}else{Throw "File '$($_)' not found"} })]
        [System.IO.FileInfo]$DBFile,

        [Parameter(Mandatory=$true)]
        [ValidateScript({ if(Test-Path -Path $($_) ){$true}else{Throw "File '$($_)' not found"} })]
        [System.IO.FileInfo]$ScriptFile,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SqlTableName
    )

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')
    $InstallArgs = @{}
    $InstallArgs.FilePath     = "pwsh.exe"
    $InstallArgs.ArgumentList = @()
    $InstallArgs.ArgumentList += "-file $($ScriptFile.FullName) -DBFile $DBFile -SqlTableName $SqlTableName"
    Start-Process @InstallArgs -Wait -NoNewWindow
    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')

}
#endregion

#region Main
enum OSType {
    Linux
    Mac
    Windows
}

if($PSVersionTable.PSVersion.Major -lt 6){
    $CurrentOS = [OSType]::Windows
}else{
    if($IsMacOS)  {$CurrentOS = [OSType]::Mac}
    if($IsLinux)  {$CurrentOS = [OSType]::Linux}
    if($IsWindows){$CurrentOS = [OSType]::Windows}
}
#endregion

#region Pode server
if($CurrentOS -eq [OSType]::Windows){
    if(Test-IsElevated -OS $CurrentOS) {
        $null = Set-HostEntry -Name 'psxi' -Elevated
        Start-PodeServer {

            Write-Host "Running on Windows with elevated Privileges since $(Get-Date)" -ForegroundColor Red
            # Get-PodeConfig | Out-Default

            Use-PodeWebTemplates -Title "$((Get-PodeConfig).PSXi.AppName) v$((Get-PodeConfig).PSXi.Version)" -Theme Dark -NoPageFilter #-HideSidebar
            New-PodeLoggingMethod -File -Name 'requests' -MaxDays 4 | Enable-PodeRequestLogging
            New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging
        
            # Initialize new SQLite database
            $DBRoot       = Join-Path $($PSScriptRoot).Replace('bin','pode') -ChildPath 'db'
            $DBFullPath   = Join-Path $DBRoot -ChildPath 'psxi.db'
            New-SqlLiteDB -DBFile $DBFullPath
            
            # Start FileWatcher for /pode/upload
            Invoke-FileWatcher

            # Set pode routes for web-sites
            Set-PodeRoutes

            Write-Host "Press Ctrl. + C to terminate the Pode server" -ForegroundColor Yellow

        } -RootPath $($PSScriptRoot).Replace('bin','pode')
    }else{
        Write-Host "Running on Windows and start new session with elevated Privileges" -ForegroundColor Green
        if($PSVersionTable.PSVersion.Major -lt 6){
            Start-Process "$psHome\powershell.exe" -Verb Runas -ArgumentList $($MyInvocation.MyCommand.Name)
        }else{
            Start-Process "$psHome\pwsh.exe" -Verb Runas -ArgumentList $($MyInvocation.MyCommand.Name)
        }
    }
}else{
    # Start-PodeServer {
    #     if(Test-IsElevated -OS $CurrentOS) {
    #         $IsRoot = 'with elevated Privileges'
    #         $null = Set-HostEntry -Name 'psxi' -Elevated
    #     }else{
    #         $IsRoot = 'as User'
    #         $null = Set-HostEntry -Name 'psxi'
    #     }
    #     Write-Host "Running on Mac $($IsRoot) since $(Get-Date)" -ForegroundColor Cyan
    #     Write-Host "Press Ctrl. + C to terminate the Pode server" -ForegroundColor Yellow

    #     Invoke-FileWatcher
    #     Set-PodeRoutes
    
    # } -RootPath $($PSScriptRoot).Replace('bin','pode')
    "Not supported OS" | Out-Default
}
#endregion