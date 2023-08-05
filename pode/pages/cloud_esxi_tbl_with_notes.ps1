<#
    Cloud Zone
#>
$GroupName = (Get-PodeConfig).PSXi.Group2

Add-PodeWebPage -Group $($GroupName) -Name "$($GroupName) ESXi Host Table" -Title "$($GroupName) ESXi Host Inventory" -Icon 'cloud' -ArgumentList $GroupName -ScriptBlock {
    param($GroupName)

    #region module
    if(-not(Get-InstalledModule -Name mySQLite -ea SilentlyContinue)){
        Install-Module -Name mySQLite -Force
        $Error.Clear()
    }
    if(-not(Get-Module -Name mySQLite)){ Import-Module -Name mySQLite }
    #endregion

    #region Breadcrumb
    Set-PodeWebBreadcrumb -Items @(
        New-PodeWebBreadcrumbItem -Name 'Home' -Url '/'
        New-PodeWebBreadcrumbItem -Name "$GroupName ESXi Host Inventory" -Url "/pages/PageName?value=$($GroupName) ESXi Hosts Table" -Active
    )
    #endregion Breadcrumb
    
    #region Defaults
    $PodeRoot     = $($PSScriptRoot).Replace('pages','db')
    $PodeDB       = Join-Path $PodeRoot -ChildPath 'psxi.db'
    $PSXiViews    = (Get-PodeConfig).PSXi.Views
    $SqlViewName  = switch -regex ($PSXiViews){ $GroupName { $_ } }
    $SqlNotesTableName = "$($SqlViewName.Replace('view_',''))Notes"
    #endregion Defaults

    if(Test-Path $PodeDB){

        #region Get data from SQLite
        $TableExists = foreach($item in $SqlViewName){
            # $item | Out-Default
            $SqliteQuery = "SELECT * FROM sqlite_master WHERE name like '$item'"
            Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
        }

        if([String]::IsNullOrEmpty($TableExists)){
            New-PodeWebCard -Name 'Warning' -Content @(
                New-PodeWebAlert -Value "Could not find view in $($PodeDB)" -Type Warning
                New-PodeWebAlert -Value "Please upload CSV-files for ($($SqlViewName))" -Type Important
            )
            break
        }else{
            $MySQLiteDB = Open-MySQLiteDB -Path $PodeDB
            if([String]::IsNullOrEmpty($MySQLiteDB)){
                New-PodeWebCard -Name 'Warning' -Content @(
                    New-PodeWebAlert -Value "Could not connect to $($PodeDB)" -Type Warning
                )
                break
            }else{
                $i = $ii = 200
                $SqlViewName = $item
                $SqliteQuery  = "Select * from $($SqlViewName)"
                $FullDB       = Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
                [datetime]$Created = $FullDB.Created | Select-Last 1
                $VIServer     = $FullDB | Group-Object vCenterServer | Select-Object -ExpandProperty Name
                $Properties = (Get-PodeConfig).PSXi.TableHeader
            }
        }
        #endregion Get data from SQLite

        if($MySQLiteDB){

            #region Summary
            New-PodeWebCard -Name Summary -DisplayName "Summary of $GroupName" -Content @(
                New-PodeWebText -Value "Last update: $(Get-Date $Created -f 'yyyy-MM-dd HH:mm:ss') "  
                New-PodeWebBadge -Colour Green -Value "$($VIServer.Count) vCenter"
                $TotalCluster = $FullDB | Group-Object Cluster
                New-PodeWebBadge -Colour Cyan -Value "$($TotalCluster.Count) Cluster"
                $ESXiHosts = $FullDB | Group-Object HostName
                New-PodeWebBadge -Colour Blue -Value "$($ESXiHosts.Count) ESXiHosts"
                $VersionGroup = Invoke-MySQLiteQuery -Path $PodeDB -Query "Select Version, COUNT(Version) AS Count from $($SqlViewName) Group by Version"
                for($i = 0; $i -lt $VersionGroup.count; $i++ ){
                    # "$($SqlViewName) : $($VersionGroup[$i].Version) : $($VersionGroup[$i].Count)" | Out-Default
                    switch -Regex ($VersionGroup[$i].Version){
                        '^7\.0'   {$Colour = 'Green'}
                        '^6\.7'   {$Colour = 'Yellow'}
                        '^6\.5'   {$Colour = 'Red'}
                        default {$Colour = 'Dark'}
                    }
                    if($VersionGroup[$i].Count -gt 0){
                        New-PodeWebBadge -Colour $Colour -Value "V$($VersionGroup[$i].Version) ($($VersionGroup[$i].Count))"
                    }
                }
            )
            #endregion Summary

            #region Search
            New-PodeWebForm -Id "Form$($GroupName)" -Name "Search for ESXiHost" -AsCard -ShowReset -ArgumentList @($Properties, $PodeDB, $SqlViewName) -ScriptBlock {
                param($Properties, $PodeDB, $SqlViewName)
                $SqliteQuery = "Select * from $($SqlViewName) Where HostName Like '%$($WebEvent.Data.Search)%' Order by vCenterServer"
                Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery | Out-PodeWebTable -Sort
            } -Content @(
                New-PodeWebTextbox -Id "Search$($GroupName)" -Name 'Search' -DisplayName 'HostName' -Type Text -NoForm -Width '400px' -Placeholder 'Enter a HostName or leave it empty to load all Hosts'
            )
            #endregion Search
        }

        New-PodeWebAccordion -Mode Collapsed -Bellows @(

            New-PodeWebBellow -Name "$GroupName ESXiHosts Notes" -Content @(

                New-PodeWebContainer -NoBackground -Content @(

                    #region Table ESXiNotes
                    New-PodeWebTable -Id "$($GroupName)TblNotes" -Name "$($GroupName)TableESXiNotes" -DisplayName "ESXi Notes" -AsCard -SimpleSort -NoRefresh -NoExport -Click -DataColumn HostName -ClickScriptBlock{
                        param($Properties, $item, $PodeDB, $SqlNotesTableName, $Cluster)
                        $SqliteQuery = "Select * from $($SqlNotesTableName)"
                        Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
                    } -Compact -ArgumentList @($Properties, $item, $PodeDB, $SqlNotesTableName, $Cluster) -ScriptBlock {
                        param($Properties, $item, $PodeDB, $SqlNotesTableName, $Cluster)
                        $SqliteQuery = "Select * from $($SqlNotesTableName)"
                        Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
                    }
                    #endregion Table ESXiNotes

                    #region Add ESXiNotes
                    New-PodeWebForm -Id "$($GroupName)AddESXiNotes" -Name "Add Notes for ESXiHost" -ShowReset -AsCard -ArgumentList @($GroupName, $PodeDB, $SqlNotesTableName) -ScriptBlock {
                        param($GroupName, $PodeDB, $SqlNotesTableName)
                        $SqliteQuery = "INSERT INTO $($SqlNotesTableName) (HostName, Notes) VALUES ('$($WebEvent.Data.AddHostName)', '$($WebEvent.Data.Notes)')"
                        Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
                        Sync-PodeWebTable -Name "$($GroupName)TableESXiNotes"
                        Show-PodeWebToast -Message "Notes for $($WebEvent.Data.AddHostName) inserted"
                    } -Content @(
                        New-PodeWebTextbox -Name 'AddHostName' -DisplayName 'HostName' -Placeholder 'ESXiHost' -AutoComplete {
                            $PodeRoot     = $($PSScriptRoot).Replace('pages','db')
                            $PodeDB       = Join-Path $PodeRoot -ChildPath 'psxi.db'                        
                            return @(Invoke-MySQLiteQuery -Path $PodeDB -Query "SELECT HostName FROM 'cloud_ESXiHosts'").HostName
                        }
                        New-PodeWebTextbox -Name 'Notes' -Placeholder 'New Notes for this ESXiHost'
                    )
                    #endregion Add ESXiNotes

                    #region Remove ESXiNotes
                    New-PodeWebForm -Id "$($GroupName)RemoveESXiNotes" -Name "Remove Notes of ESXiHost" -ShowReset -AsCard -ArgumentList @($GroupName, $PodeDB, $SqlNotesTableName) -ScriptBlock {
                        param($GroupName, $PodeDB, $SqlNotesTableName)
                        $SqliteQuery = "DELETE FROM $($SqlNotesTableName) WHERE (HostName like '%$($WebEvent.Data.RemoveHostName)%')"
                        Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
                        Sync-PodeWebTable -Name "$($GroupName)TableESXiNotes"
                        Show-PodeWebToast -Message "Notes for $($WebEvent.Data.RemoveHostName) removed"
                    } -Content @(
                        New-PodeWebTextbox -Name 'RemoveHostName' -DisplayName 'HostName' -Placeholder 'ESXiHost' -AutoComplete {
                            $PodeRoot     = $($PSScriptRoot).Replace('pages','db')
                            $PodeDB       = Join-Path $PodeRoot -ChildPath 'psxi.db'                        
                            return @(Invoke-MySQLiteQuery -Path $PodeDB -Query "SELECT HostName FROM 'cloud_ESXiHosts'").HostName
                        }
                    )
                    #endregion Remove ESXiNotes

                )

            )
        )

        #region tables
        if($MySQLiteDB){
            New-PodeWebContainer -NoBackground -Content @(

                #region Tabs
                New-PodeWebTabs -Tabs @(
                    foreach($item in $VIServer){

                        $i ++
                        $vCenter = (($item -split '\.')[0]).ToUpper()
                        $VICluster = $FullDB | Where-Object vCenterServer -match $item | Group-Object Cluster | Select-Object -ExpandProperty Name
                        $ESXiHosts = $FullDB | Where-Object vCenterServer -match $item | Group-Object HostName
                        
                        New-PodeWebTab -Id "Tab$($i)" -Name "vCenter $($vCenter)" -Layouts @(
                            
                            #region Badge
                            New-PodeWebCard -NoTitle -NoHide -Content @(
                                New-PodeWebText -Value "vCenter «$($vCenter)» contains:" -Style Bold
                                New-PodeWebBadge -Colour Cyan -Value "$($VICluster.count) Cluster"
                                New-PodeWebBadge -Colour Blue -Value "$($ESXiHosts.Count) ESXiHosts"
                            )
                            #endregion

                            foreach($Cluster in $VICluster){
                                $ii ++

                                #region Badge
                                New-PodeWebParagraph -Elements @(
                                    New-PodeWebText -Value "Cluster «$($Cluster)» contains:" -Style Italics
                                    $ESXiHosts = $FullDB | Where-Object vCenterServer -match $item | Where-Object Cluster -match $Cluster | Group-Object HostName
                                    New-PodeWebBadge -Colour Blue -Value "$($ESXiHosts.Count) ESXiHosts"
                                    $FullDB | Where-Object vCenterServer -match $item | Where-Object Cluster -match $Cluster| Group-Object Version | ForEach-Object {
                                        switch -Regex ($_.Name){
                                            '^7\.0'   {$Colour = 'Green'}
                                            '^6\.7'   {$Colour = 'Yellow'}
                                            '^6\.5'   {$Colour = 'Red'}
                                            default {$Colour = 'Dark'}
                                        }
                                        if($_.count -gt 0){
                                            New-PodeWebBadge -Colour $Colour -Value "V$($_.Name) ($($_.Count))"
                                        }
                                    }
                                )
                                #endregion
    
                                #region Table ESXiNotes
                                New-PodeWebTable -Id "Table$($ii)" -Name "VC$($ii)" -DisplayName "Cluster $($Cluster)" -AsCard -SimpleSort -NoExport -NoRefresh -Click -DataColumn HostName -ClickScriptBlock{
                                    param($Properties, $item, $PodeDB, $SqlViewName, $Cluster)
                                    $SqliteQuery = "Select * from $($SqlViewName) Where (HostName = '$($WebEvent.Data.Value)')"
                                    $Result = Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery #-As Hashtable | Select-Object -ExpandProperty Values
                                    foreach($item in $Result){ $Message = "$($Message), $($item)" }
                                    Show-PodeWebToast -Title $($WebEvent.Data.Value) -Message $Message.TrimStart(', ') -Duration 900000
                                } -Compact -ArgumentList @($Properties, $item, $PodeDB, $SqlViewName, $Cluster) -ScriptBlock {
                                    param($Properties, $item, $PodeDB, $SqlViewName, $Cluster)
                                    $SqliteQuery = "Select * from $($SqlViewName) Where (vCenterServer Like '%$($item)%') And (Cluster = '$Cluster')"
                                    Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery | Select-Object $Properties
                                }
                                #endregion Table ESXiNotes

                            }
                        )
                    }
                )
                #endregion
            )
        }
        #endregion tables
        
    }else{
        New-PodeWebCard -Name 'Warning' -Content @(
            New-PodeWebAlert -Value "Could not find $($PodeDB)" -Type Warning
        )
    }

}