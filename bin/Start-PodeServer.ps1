#Requires -Modules Pode, Pode.Web, PSHTML, mySQLite 
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

    New-PodeLoggingMethod -File -Name 'requests' -MaxDays 4 | Enable-PodeRequestLogging
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    Use-PodeWebTemplates -Title "PSXi App" -Theme Auto

    Add-PodeRoute -Method Get -Path '/classic_ESXiHosts_diag' -ScriptBlock {
        Write-PodeViewResponse -Path 'Classic-ESXiHost-Diagram'
    }

    Add-PodeRoute -Method Get -Path '/cloud_ESXiHosts_diag' -ScriptBlock {
        Write-PodeViewResponse -Path 'Cloud-ESXiHost-Diagram'
    }

    # Add Navbar
    $Properties = @{
        Name = 'ESXiHost-Diagram'
        Url  = '/diag'
        Icon = 'chart-tree'
    }
    $navgithub  = New-PodeWebNavLink @Properties -NewTab
    Set-PodeWebNavDefault -Items $navgithub

    # Add dynamic pages
    $PodeRoot = $($PSScriptRoot).Replace('bin','pode')
    foreach($item in (Get-ChildItem (Join-Path $PodeRoot -ChildPath 'pages'))){
        . "$($item.FullName)"
    }
    Add-PodeEndpoint -Address * -Port 5989 -Protocol Http -Hostname 'psxi'

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')

}

function Invoke-FileWatcher{
    <#
        Returns:
        - Changed
        - classic_ESXiHosts.csv
        - D:\github.com\PSXiDiag\pode\input\classic_ESXiHosts.csv
        #>
    [CmdletBinding()]
    param()

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')

    $WatchFolder = Join-Path $($PSScriptRoot).Replace('bin','pode') -ChildPath 'input'

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

                        "Database $DBFullPath already available" | Out-PodeHost
                        # Read header from csv-file and set it as column-names to the table
                        $th = (Get-Content -Path $FileEvent.FullPath -Encoding utf8 -TotalCount 1).Split(';') + 'Created'
                        "Ovewrite the Table $($TableName) if it already exists!" | Out-PodeHost
                        New-MySQLiteDBTable -Path $DBFullPath -TableName $TableName -ColumnNames $th -Force
                        # Add ID as primary-key th the table
                        Invoke-MySQLiteQuery -Path $DBFullPath -query "ALTER TABLE $TableName ADD ID [INTEGER PRIMARY KEY];"

                        switch -Regex ($TableName){
                            '_ESXiHosts' {
                                "Add content 'ESXiHost' to the table" | Out-PodeHost
                                Update-ESXiHostTable -CSVFile $FileEvent.FullPath -DBFile $DBFullPath -SqlTableName $TableName
                                # switch -Regex ($FileEvent.FullPath){
                                #     'classic*' { $Title = 'Classic'}
                                #     'cloud*'   { $Title = 'Cloud'}
                                # }
                                # $file2Exec  = Join-Path $PSScriptRoot -ChildPath "New-PshtmlESXiDiag.ps1"
                                # $title2Exec = "$($Title)-ESXiHost-Diagram"
                                # $data = Import-Csv -Delimiter ';' -Path $FileEvent.FullPath -Encoding utf8

                                # $file2Exec  | Out-PodeHost
                                # $title2Exec | Out-PodeHost

                                # . "$file2Exec -InputObject $data -Title $title2Exec"

                                # $InstallArgs = @{}
                                # $InstallArgs.FilePath     = "pwsh.exe"
                                # $InstallArgs.ArgumentList = @()
                                # $InstallArgs.ArgumentList += "-file '$exec'"
                                # Start-Process @InstallArgs -Wait
                                                        
                            }
                            '_summary' {
                                "Add content 'Summary' to the table" | Out-PodeHost
                                Update-SummaryTable -CSVFile $FileEvent.FullPath -DBFile $DBFullPath -SqlTableName $TableName
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
        [string]$SqlTableName
    )

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')

    Write-Verbose "($data | Select-Object -First 1 | Format-Table | Out-String)"
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
            Write-Host "Press Ctrl. + C to terminate the Pode server" -ForegroundColor Yellow

            # Initialize new SQLite database
            $DBRoot       = Join-Path $($PSScriptRoot).Replace('bin','pode') -ChildPath 'db'
            $DBFullPath   = Join-Path $DBRoot -ChildPath 'psxi.db'
            New-SqlLiteDB -DBFile $DBFullPath
            
            # Start FileWatcher for /pode/input
            Invoke-FileWatcher

            # Set pode routes for web-sites
            Set-PodeRoutes
            
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