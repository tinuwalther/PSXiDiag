Add-PodeWebPage -Group 'Cloud' -Name 'Cloud ESXi Hosts Diagram' -Title 'Cloud ESXi Host Diagram' -Icon 'server' -ScriptBlock {
    
    Set-PodeWebBreadcrumb -Items @(
        New-PodeWebBreadcrumbItem -Name 'Home' -Url '/'
        New-PodeWebBreadcrumbItem -Name 'Cloud' -Url '/'
        New-PodeWebBreadcrumbItem -Name 'Cloud ESXi Host Diagram' -Url '/pages/PageName?value=Cloud ESXi Hosts Diagram' -Active
    )

    New-PodeWebIFrame -Url '/cloud_ESXiHosts_diag'

}