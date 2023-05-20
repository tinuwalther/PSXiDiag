<#
    Cloud Zone
#>
$GroupName = (Get-PodeConfig).PSXi.Group2
Add-PodeWebPage -Group $GroupName -Name "$GroupName ESXi Host Diagram" -Title "$GroupName ESXi Host Diagram" -Icon 'cloud' -ArgumentList $GroupName -ScriptBlock {
    param($GroupName)

    Set-PodeWebBreadcrumb -Items @(
        New-PodeWebBreadcrumbItem -Name 'Home' -Url '/'
        New-PodeWebBreadcrumbItem -Name "$GroupName ESXi Host Diagram" -Url "/pages/PageName?value=$($GroupName) ESXi Hosts Diagram" -Active
    )

    New-PodeWebIFrame -Url '/cloud_ESXiHosts_diag'

}