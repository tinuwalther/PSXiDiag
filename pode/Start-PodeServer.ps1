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
function Test-IsAdministrator {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [OSType]$OS
    )

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')
    if($OS -eq [OSType]::Windows){
        $user = [Security.Principal.WindowsIdentity]::GetCurrent()
        $ret  = (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    }elseif($OS -eq [OSType]::Mac){
        $ret = ((id -u) -eq 0)
    }

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')
    return $ret
}

function Set-PodeRoutes {
    [CmdletBinding()]
    param()

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', "$($MyInvocation.MyCommand.Name)" -Join ' ')

    Add-PodeRoute -Method Get -Path '/' -ScriptBlock {
        Write-PodeViewResponse -Path 'Pshtml-ESXiHost-Inventory'
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
    if(Test-IsAdministrator -OS $CurrentOS) {
        Start-PodeServer {
            Write-Host "Running on Windows with elevated Privileges since $(Get-Date)" -ForegroundColor Red
            Write-Host "Press Ctrl. + C to terminate the Pode server" -ForegroundColor Yellow

            Add-PodeEndpoint -Address * -Port 5989 -Protocol Http -Hostname 'pspode'
            New-PodeLoggingMethod -File -Name 'requests' -MaxDays 4 | Enable-PodeRequestLogging

            Set-PodeRoutes
        } 
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
        if(Test-IsAdministrator -OS $CurrentOS) {
            $IsRoot = 'with elevated Privileges'
        }else{
            $IsRoot = 'as User'
        }
        Write-Host "Running on Mac $($IsRoot) since $(Get-Date)" -ForegroundColor Cyan
        Write-Host "Press Ctrl. + C to terminate the Pode server" -ForegroundColor Yellow

        Add-PodeEndpoint -Address * -Port 5989 -Protocol Http -Hostname 'pspode'
        New-PodeLoggingMethod -File -Name 'requests' -MaxDays 4 | Enable-PodeRequestLogging

        Set-PodeRoutes
        
    }
}
#endregion