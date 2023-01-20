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

function Test-IsAdministrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if($CurrentOS -eq [OSType]::Windows){
    if(Test-IsAdministrator) {
        Start-PodeServer {
            Write-Host "Running on Windows with elevated Privileges" -ForegroundColor Red
            Write-Host "Press Ctrl. + C to terminate the Pode server" -ForegroundColor Yellow

            Add-PodeEndpoint -Address * -Port 5989 -Protocol Http -Hostname 'pspode'

            Add-PodeRoute -Method Get -Path '/' -ScriptBlock {
                Write-PodeViewResponse -Path 'index.md'
            }
            Add-PodeRoute -Method Get -Path '/html' -ScriptBlock {
                Write-PodeViewResponse -Path 'html/HTML-ESXiHost-Inventory'
            }
            Add-PodeRoute -Method Get -Path '/pshtml' -ScriptBlock {
                Write-PodeViewResponse -Path 'pshtml/PSHTML-ESXiHost-Inventory'
            }
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
        Write-Host "Running on Mac" -ForegroundColor Cyan
        Write-Host "Press Ctrl. + C to terminate the Pode server" -ForegroundColor Yellow

        Add-PodeEndpoint -Address * -Port 5989 -Protocol Http

        Add-PodeRoute -Method Get -Path '/' -ScriptBlock {
            Write-PodeViewResponse -Path 'Pshtml-ESXiHost-Inventory'
        }
        
    }
}