Add-PodeWebPage -Group 'Classic' -Name 'Classic ESXi Host Diagram' -Title 'Classic ESXi Host Diagram' -Icon 'server' -ScriptBlock {
    
    Set-PodeWebBreadcrumb -Items @(
        New-PodeWebBreadcrumbItem -Name 'Home' -Url '/'
        New-PodeWebBreadcrumbItem -Name 'Classic ESXi Host Diagram' -Url '/pages/PageName?value=Classic ESXi Hosts Diagram' -Active
    )

    New-PodeWebIFrame -Url '/classic_ESXiHosts_diag'

}
