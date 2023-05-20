<#
    Classic Zone
#>
$GroupName = (Get-PodeConfig).PSXi.Group1
Add-PodeWebPage -Group $GroupName -Name "$GroupName ESXi Host Diagram" -Title "$GroupName ESXi Host Diagram" -Icon 'server' -ArgumentList $GroupName -ScriptBlock {
    param($GroupName)

    Set-PodeWebBreadcrumb -Items @(
        New-PodeWebBreadcrumbItem -Name 'Home' -Url '/'
        New-PodeWebBreadcrumbItem -Name "$GroupName ESXi Host Diagram" -Url "/pages/PageName?value=$($GroupName) ESXi Hosts Diagram" -Active
    )

    New-PodeWebIFrame -Url '/classic_ESXiHosts_diag'

}
