Add-PodeWebPage -Group 'Classic' -Name 'Classic ESXi Hosts Diagram' -Title 'Classic ESXi Host Diagram' -Icon 'server' -ScriptBlock {
    #region module
    if(-not(Get-InstalledModule -Name mySQLite -ea SilentlyContinue)){
        Install-Module -Name mySQLite -Force
        $Error.Clear()
    }
    if(-not(Get-Module -Name mySQLite)){ Import-Module -Name mySQLite }
    #endregion
    
    Set-PodeWebBreadcrumb -Items @(
        New-PodeWebBreadcrumbItem -Name 'Home' -Url '/'
        New-PodeWebBreadcrumbItem -Name 'Classic' -Url '/'
        New-PodeWebBreadcrumbItem -Name 'Classic ESXi Host Diagram' -Url '/pages/PageName?value=Classic ESXi Hosts Diagram' -Active
    )

    New-PodeWebCard -NoTitle -NoHide -Content @(
        New-PodeWebIFrame -Url '/classic_ESXiHosts_diag'
    )

}
