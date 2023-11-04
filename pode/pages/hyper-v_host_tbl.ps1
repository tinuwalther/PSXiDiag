<#
    Cloud Zone
#>
$GroupName = (Get-PodeConfig).PSXi.Group3
$PageName  = "1. $($GroupName) Hosts"
$PageTitle = "1. $($GroupName) Host Inventory"

Add-PodeWebPage -Group $($GroupName) -Name $PageName -Title $PageTitle -Icon 'cloud' -ArgumentList @($GroupName, $PageName, $PageTitle) -ScriptBlock {
    param($GroupName, $PageName, $PageTitle)

    #region Breadcrumb
    Set-PodeWebBreadcrumb -Items @(
        New-PodeWebBreadcrumbItem -Name 'Home' -Url '/'
        New-PodeWebBreadcrumbItem -Name $PageTitle -Url "/pages/PageName?value=$($PageTitle)" -Active
    )
    #endregion Breadcrumb

    # if(Test-Path $global:PodeDB){

        New-PodeWebContainer -NoBackground -Content @(

            # if($MySQLiteDB){

                #region Search
                New-PodeWebForm -Id "Form$($GroupName)" -Name "Search for Host" -AsCard -ShowReset -ArgumentList @($Properties, $global:PodeDB, $SqlViewName) -ScriptBlock {
                    param($Properties, $global:PodeDB, $SqlViewName)
                    $SqliteQuery = "Select * from $($SqlViewName) Where HostName Like '%$($WebEvent.Data.Search)%' Order by vCenterServer"
                    Invoke-MySQLiteQuery -Path $global:PodeDB -Query $SqliteQuery | Out-PodeWebTable -Sort
                } -Content @(
                    New-PodeWebTextbox -Id "Search$($GroupName)" -Name 'Search' -DisplayName 'HostName' -Type Text -NoForm -Width '450px' -Placeholder 'Enter a HostName or leave it empty to load all Hosts' -CssClass 'no-form'
                )
                #endregion Search

            # }

        )
        
    # }else{
    #     New-PodeWebCard -Name 'Warning' -Content @(
    #         New-PodeWebAlert -Value "Could not find $($global:PodeDB)" -Type Warning
    #     )
    # }

}