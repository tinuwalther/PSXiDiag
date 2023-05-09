#Requires -Modules Pode, PSHTML, mySQLite 
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

    Add-PodeRoute -Method Get -Path '/' -ScriptBlock {
        Write-PodeViewResponse -Path 'PSHTML-ESXiHost-Inventory'
    }

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')

}

function Invoke-FileWatcher{
    <#
        Returns:
        - Changed
        - Inventory.csv
        - D:\github.com\PSXiDiag\pode\input\Inventory.csv
        #>
    [CmdletBinding()]
    param()

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')

    $WatchFolder = Join-Path $($PSScriptRoot).Replace('bin','pode') -ChildPath 'input'

    Add-PodeFileWatcher -EventName Changed -Path $WatchFolder -ScriptBlock {
        # file name and path
        "$($FileEvent.Name) -> $($FileEvent.Type) -> $($FileEvent.FullPath)" | Out-Default

        switch($FileEvent.Type){
            'Changed' {
                if($FileEvent.Name -match '\.csv'){
                    $DBRoot       = Join-Path $($PSScriptRoot).Replace('bin','pode') -ChildPath 'db'
                    $DBFullPath   = Join-Path $DBRoot -ChildPath ($FileEvent.Name -replace '.csv','.db')
                    if(Test-Path $DBFullPath){
                        #"$DBFullPath already available" | Out-Default
                        Update-SqlLiteDB -CSVFile $FileEvent.FullPath -DBFile $DBFullPath -SqlTableName 'ESXHosts'
                    }else{
                        #"$DBFullPath not available" | Out-Default
                        New-SqlLiteDB -CSVFile $FileEvent.FullPath -DBFile $DBFullPath -SqlTableName 'ESXHosts'
                    }
                }
            }
            default {
                $FileEvent.Type | Out-Default
            }
        }
    }
    
    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')
}

function Update-SqlLiteDB{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({ if(Test-Path -Path $($_) ){$true}else{Throw "File '$($_)' not found"} })]
        [System.IO.FileInfo]$CSVFile,

        [Parameter(Mandatory=$true)]
        [ValidateScript({ if(Test-Path -Path $($_) ){$true}else{Throw "File '$($_)' not found"} })]
        [System.IO.FileInfo]$DBFile,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SqlTableName
    )

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')

    $sqlite = Invoke-MySQLiteQuery -Path $DBFile.FullName -Query "Select * from $SqlTableName"
    $data   = Import-Csv -Delimiter ';' -Path $CSVFile.FullName -Encoding utf8

    $Compare = Compare-Object -ReferenceObject $sqlite -DifferenceObject $data -IncludeEqual -PassThru
    foreach($item in $Compare){
        switch($item.SideIndicator){
            '<=' { 
                # Only in SQLiteDB, remove it from SQLiteDB
                "$($item.HostName) only in ReferenceObject" 
            }  
            '=>' { 
                # Only in CSVFile, add it to SQLiteDB
                "$($item.HostName) only in DifferenceObject" 
            } 
            '==' { 
                # Update all properties
                "$($item.HostName) is in sync"
            }
        }
    }

    if(
        ($data | Select-Object -last 1 -ExpandProperty HostName) -eq
        ($sqlite | Select-Object -Last 1 -ExpandProperty HostName)
    ){
        "Update $($DBFile) on table $($SqlTableName)" | Out-Default
        $data | foreach-object -begin { 
            $MySQLiteDB = Open-MySQLiteDB -Path $DBFullPath
        } -process { 
            $SqliteQuery = "Update $($SqlTableName)
            Set
                'Version'          = '$($_.Version)',
                'Manufacturer'     = '$($_.Manufacturer)',
                'Model'            = '$($_.Model)',
                'vCenterServer'    = '$($_.vCenterServer)',
                'Cluster'          = '$($_.Cluster)',
                'PhysicalLocation' = '$($_.PhysicalLocation)',
                'ConnectionState'  = '$($_.ConnectionState)',
                'Created'          = '$(Get-Date)'
            WHERE HostName LIKE '$($_.HostName)'"
            Invoke-MySQLiteQuery -connection $MySQLiteDB -keepalive -query $SqliteQuery
        } -end { 
            Close-MySQLiteDB $MySQLiteDB
        }
    }else{
        "Insert into $($DBFile) on table $($SqlTableName)" | Out-Default
        $data | foreach-object -begin { 
            $MySQLiteDB = Open-MySQLiteDB -Path $DBFullPath
        } -process { 
            $SqliteQuery = "Insert into $($SqlTableName) Values(
                '$($_.HostName)',
                '$($_.Version)',
                '$($_.Manufacturer)',
                '$($_.Model)',
                '$($_.vCenterServer)',
                '$($_.Cluster)',
                '$($_.PhysicalLocation)',
                '$($_.ConnectionState)',
                '$(Get-Date)'
            )"
            Invoke-MySQLiteQuery -connection $MySQLiteDB -keepalive -query $SqliteQuery
        } -end { 
            Close-MySQLiteDB $MySQLiteDB
        }
    }
    
    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')
}

function New-SqlLiteDB{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({ if(Test-Path -Path $($_) ){$true}else{Throw "File '$($_)' not found"} })]
        [System.IO.FileInfo]$CSVFile,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$DBFile,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SqlTableName
    )

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')

    "Create $($DBFile) with table $($SqlTableName)" | Out-Default
    $SqlTypeName  = 'PSXi'    
    $data = Import-Csv -Delimiter ';' -Path $CSVFile.FullName -Encoding utf8
    $data | Add-Member NoteProperty Created $((Get-Date (Get-Date).AddDays(-5)))
    $data | ConvertTo-MySQLiteDB -Path $DBFile -TableName $SqlTableName -TypeName $SqlTypeName -Force -Primary HostName
    
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
        $null = Set-HostEntry -Name 'pspode' -Elevated
        Start-PodeServer {
            Write-Host "Running on Windows with elevated Privileges since $(Get-Date)" -ForegroundColor Red
            Write-Host "Press Ctrl. + C to terminate the Pode server" -ForegroundColor Yellow

            #Add-PodeEndpoint -Address * -Port 5989 -Protocol Http -Hostname 'pspode'
            #New-PodeLoggingMethod -File -Name 'requests' -MaxDays 4 | Enable-PodeRequestLogging

            #Set-PodeRoutes
            Invoke-FileWatcher
            
        } -RootPath $($PSScriptRoot).Replace('bin','pode')
    }else{
        Write-Host "Running on Windows and start new session with elevated Privileges" -ForegroundColor Green
        if($PSVersionTable.PSVersion.Major -lt 6){
            Start-Process "$psHome\powershell.exe" -Verb Runas -ArgumentList $($MyInvocation.MyCommand.Name)
        }else{
            Start-Process "$psHome\pwsh.exe" -Verb Runas -ArgumentList $($MyInvocation.MyCommand.Name)
        }
    }
}elseif($CurrentOS -eq [OSType]::Mac){
    Start-PodeServer {
        if(Test-IsElevated -OS $CurrentOS) {
            $IsRoot = 'with elevated Privileges'
            $null = Set-HostEntry -Name 'pspode' -Elevated
        }else{
            $IsRoot = 'as User'
            $null = Set-HostEntry -Name 'pspode'
        }
        Write-Host "Running on Mac $($IsRoot) since $(Get-Date)" -ForegroundColor Cyan
        Write-Host "Press Ctrl. + C to terminate the Pode server" -ForegroundColor Yellow

        #Add-PodeEndpoint -Address * -Port 5989 -Protocol Http -Hostname 'pspode'
        #New-PodeLoggingMethod -File -Name 'requests' -MaxDays 4 | Enable-PodeRequestLogging

        #Set-PodeRoutes
        Invoke-FileWatcher
    
    } -RootPath $($PSScriptRoot).Replace('bin','pode')
}
#endregion