<#
    Classic Zone
#>
$GroupName = (Get-PodeConfig).PSXi.Group1
$PageName  = "3. $($GroupName) ESXi Diagram"
$PageTitle = "3. $($GroupName) ESXi Host Diagram"

Add-PodeWebPage -Group $GroupName -Name $PageName -Title $PageTitle -Icon 'server' -ArgumentList @($GroupName, $PageName, $PageTitle) -ScriptBlock {
    param($GroupName, $PageNam, $PageTitle)

    Set-PodeWebBreadcrumb -Items @(
        New-PodeWebBreadcrumbItem -Name 'Home' -Url '/'
        New-PodeWebBreadcrumbItem -Name $PageTitle -Url "/pages/PageName?value=$($PageName)" -Active
    )

    New-PodeWebIFrame -Url '/classic_ESXiHosts_diag'

}
