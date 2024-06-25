<#
    Classic Zone
#>
Import-PodeWebStylesheet -Url 'psxi.css'

$GroupName = (Get-PodeConfig).PSXi.Group1
$PageName  = "2. $($GroupName) ESXi Datastores"
$PageTitle = "2. $($GroupName) ESXi Datastore Inventory"

Add-PodeWebPage -Group $($GroupName) -Name $PageName -Title $PageTitle -Icon 'server' -ArgumentList @($GroupName, $PageName, $PageTitle) -ScriptBlock {
    param($GroupName, $PageName, $PageTitle)

    #region module
    if(-not(Get-InstalledModule -Name mySQLite -ea SilentlyContinue)){
        Install-Module -Name mySQLite -Force
        $Error.Clear()
    }
    if(-not(Get-Module -Name mySQLite)){ Import-Module -Name mySQLite }
    #endregion
    
    #region Defaults
    $PodeRoot            = $($PSScriptRoot).Replace('pages','db')
    $global:PodeDB       = Join-Path $PodeRoot -ChildPath 'psxi.db'
    $PSXiViews           = (Get-PodeConfig).PSXi.Tables
    $SqlViewName         = switch -regex ($PSXiViews){ $GroupName { $_ } }
    $global:SqlTableName = "$($SqlViewName.Replace('view_',''))"
    # $SqlNotesTableName   = "$($SqlViewName.Replace('view_',''))Notes"
    #endregion Defaults

    #region Breadcrumb
    Set-PodeWebBreadcrumb -Items @(
        New-PodeWebBreadcrumbItem -Name 'Home' -Url '/'
        New-PodeWebBreadcrumbItem -Name $PageTitle -Url "/pages/PageName?value=$($PageName)" -Active
    )
    #endregion Breadcrumb

    if(Test-Path $global:PodeDB){

        #region Get data from SQLite
        $TableExists = foreach($item in $SqlViewName){
            $SqliteQuery = "SELECT * FROM sqlite_master WHERE name like '$item'"
            Invoke-MySQLiteQuery -Path $global:PodeDB -Query $SqliteQuery
        }

        if([String]::IsNullOrEmpty($TableExists)){
            New-PodeWebCard -Name 'Warning' -Content @(
                New-PodeWebAlert -Value "Could not find view in $($global:PodeDB)" -Type Warning
                New-PodeWebAlert -Value "Please upload CSV-files for ($($SqlViewName))" -Type Important
            )
            break
        }else{
            $MySQLiteDB = Open-MySQLiteDB -Path $global:PodeDB
            if([String]::IsNullOrEmpty($MySQLiteDB)){
                New-PodeWebCard -Name 'Warning' -Content @(
                    New-PodeWebAlert -Value "Could not connect to $($global:PodeDB)" -Type Warning
                )
                break
            }else{
                $i  = 400
                $ii = 400
                $SqlViewName = $item
                # $item | Out-Default
                $SqliteQuery  = "Select * from $($SqlViewName)"
                $FullDB       = Invoke-MySQLiteQuery -Path $global:PodeDB -Query $SqliteQuery
                [datetime]$Created = $FullDB.Created | Select-Last 1
                $VIServer     = $FullDB | Group-Object vCenterServer | Select-Object -ExpandProperty Name
                $Properties = (Get-PodeConfig).PSXi.vmwDatastoreHeader
            }
        }
        #endregion Get data from SQLite

        New-PodeWebContainer -NoBackground -Content @(

            if($MySQLiteDB){

                #region Summary
                New-PodeWebCard -Name Summary -DisplayName "Summary of $GroupName Datastores" -Content @(
                    New-PodeWebText -Value "Last update: $(Get-Date $Created -f 'yyyy-MM-dd HH:mm:ss') "  
                    New-PodeWebBadge -Colour Green -Value "$($VIServer.Count) vCenter"
                    $TotalCluster = $FullDB | Group-Object DatastoreClusterCluster
                    New-PodeWebBadge -Colour Cyan -Value "$($TotalCluster.Count) Cluster"
                )
                #endregion Summary

                #region Search
                New-PodeWebForm -Id "Form$($GroupName)" -Name "Search for Datastore" -AsCard -ShowReset -ArgumentList @($Properties, $global:PodeDB, $SqlViewName) -ScriptBlock {
                    param($Properties, $global:PodeDB, $SqlViewName)
                    $SqliteQuery = "Select * from $($SqlViewName) Where DatastoreName Like '%$($WebEvent.Data.Search)%' Order by vCenterServer"
                    Invoke-MySQLiteQuery -Path $global:PodeDB -Query $SqliteQuery | Out-PodeWebTable -Sort
                } -Content @(
                    New-PodeWebTextbox -Id "Search$($GroupName)" -Name 'Search' -DisplayName 'Datastore' -Type Text -NoForm -Width '450px' -Placeholder 'Enter a Datastore or leave it empty to load all Datastores' -CssClass 'no-form'
                )
                #endregion Search

                New-PodeWebLine

                #region tables
                if($MySQLiteDB){
                    #region VIServer
                    foreach($item in $VIServer){
                        $i ++
                        $vCenter = (($item -split '\.')[0]).ToUpper()
                        $VICluster = $FullDB | Where-Object vCenterServer -match $item | Group-Object DatastoreCluster | Select-Object -ExpandProperty Name
                        
                        New-PodeWebCard -Id "VC$($i)" -Name "VC$($i)" -DisplayName "vCenter «$($vCenter)» contains $($VICluster.count) Cluster" -Content @(
                            foreach($Cluster in $VICluster){
                                $ii ++
                            
                                #region Badge
                                New-PodeWebText -Value "DatastoreCluster «$($Cluster)» contains:" -Style Italics
                                $Datastores = $FullDB | Where-Object vCenterServer -match $item | Where-Object DatastoreCluster -match $Cluster | Group-Object DatastoreName
                                New-PodeWebBadge -Colour Blue -Value "$($Datastores.Count) Datastores"
                                New-PodeWebLine
                                #endregion Badge
    
                                #region add table
                                New-PodeWebTable -Id "Table$($ii)" -Name "VC$($ii)" -DisplayName "DatastoreCluster $($Cluster)" -AsCard -SimpleSort -NoExport -NoRefresh -Click -DataColumn HostName -ClickScriptBlock{
                                    param($Properties, $item, $global:PodeDB, $SqlViewName, $Cluster)
                                    $SqliteQuery = "Select * from $($SqlViewName) Where (DatastoreName = '$($WebEvent.Data.Value)')"
                                    $Result = Invoke-MySQLiteQuery -Path $global:PodeDB -Query $SqliteQuery #-As Hashtable | Select-Object -ExpandProperty Values
                                    foreach($item in $Result){ $Message = "$($Message), $($item)" }
                                    Show-PodeWebToast -Title $($WebEvent.Data.Value) -Message $Message.TrimStart(', ') -Duration 900000
                                } -Compact -ArgumentList @($Properties, $item, $global:PodeDB, $SqlViewName, $Cluster) -ScriptBlock {
                                    param($Properties, $item, $global:PodeDB, $SqlViewName, $Cluster)
                                    $SqliteQuery = "Select * from $($SqlViewName) Where (vCenterServer Like '%$($item)%') And (DatastoreCluster = '$Cluster')"
                                    Invoke-MySQLiteQuery -Path $global:PodeDB -Query $SqliteQuery | Sort-Object DatastoreName | Select-Object $Properties
                                }
                                #endregion add table

                            }
                        )
                    }
                }
                #endregion tables
                
            }

        )
        
    }else{
        New-PodeWebCard -Name 'Warning' -Content @(
            New-PodeWebAlert -Value "Could not find $($global:PodeDB)" -Type Warning
        )
    }

}