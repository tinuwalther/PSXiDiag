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
        $FileEvent.Type     | Out-Default
        $FileEvent.Name     | Out-Default
        $FileEvent.FullPath | Out-Default

        switch($FileEvent.Type){
            'Changed' {
                if($FileEvent.Name -match '\.csv'){
                    Invoke-InsertToSqlLiteDB -FileName $FileEvent.Name -File $FileEvent.FullPath
                }
            }
            default {
                $FileEvent.Type | Out-Default
            }
        }
    }
    
    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')
}

function Invoke-InsertToSqlLiteDB{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$FileName,

        [Parameter(Mandatory=$true)]
        [ValidateScript({ if(Test-Path -Path $($_) ){$true}else{Throw "File '$($_)' not found"} })]
        [System.IO.FileInfo]$File
    )

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')

    $SqlTypeName  = 'PSXi'
    $SqlTableName = 'ESXHosts'
    $DBRoot       = Join-Path $($PSScriptRoot).Replace('bin','pode') -ChildPath 'db'
    $DBFullPath   = Join-Path $DBRoot -ChildPath ($FileName -replace '.csv','.db')

    if(Test-Path $DBFullPath){

        $data   = Import-Csv -Delimiter ';' -Path $File.FullName -Encoding utf8
        $sqlite = Invoke-MySQLiteQuery -Path $DBFullPath -Query "Select * from $SqlTableName"

        if(
            ($data | Select-Object -last 1 -ExpandProperty Id) -eq
            ($sqlite | Select-Object -Last 1 -ExpandProperty Id)
        ){
            Write-Warning "Records already exists"
        }else{
            Write-Host "Records not exists"
            $data | Add-Member NoteProperty Created $((Get-Date).AddDays(-2) -f 'yyyy-MM-dd HH:mm:ss.fff')
            $data | foreach-object -begin { 
                $MySQLiteDB = Open-MySQLiteDB -Path $DBFullPath
            } -process { 
                $SqliteQuery = "Insert into $($SqlTableName) Values(
                    '$($_.Id)',
                    '$($_.HostName)',
                    '$($_.Version)',
                    '$($_.Manufacturer)',
                    '$($_.Model)',
                    '$($_.vCenterServer)',
                    '$($_.Cluster)',
                    '$($_.PhysicalLocation)',
                    '$($_.ConnectionState)',
                    '$($_.Created)'
                )"
                Invoke-MySQLiteQuery -connection $MySQLiteDB -keepalive -query $SqliteQuery
            } -end { 
                Close-MySQLiteDB $MySQLiteDB
            }
        }
    }else{
        $data | ConvertTo-MySQLiteDB -Path $DBFullPath -TableName $SqlTableName -TypeName $SqlTypeName -Force -Primary Id
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
        $null = Set-HostEntry -Name 'pspode' -Elevated
        Start-PodeServer {
            Write-Host "Running on Windows with elevated Privileges since $(Get-Date)" -ForegroundColor Red
            Write-Host "Press Ctrl. + C to terminate the Pode server" -ForegroundColor Yellow

            Add-PodeEndpoint -Address * -Port 5989 -Protocol Http -Hostname 'pspode'
            New-PodeLoggingMethod -File -Name 'requests' -MaxDays 4 | Enable-PodeRequestLogging

            Set-PodeRoutes
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

        Add-PodeEndpoint -Address * -Port 5989 -Protocol Http -Hostname 'pspode'
        New-PodeLoggingMethod -File -Name 'requests' -MaxDays 4 | Enable-PodeRequestLogging

        Set-PodeRoutes
        Invoke-FileWatcher
    
    } -RootPath $($PSScriptRoot).Replace('bin','pode')
}
#endregion