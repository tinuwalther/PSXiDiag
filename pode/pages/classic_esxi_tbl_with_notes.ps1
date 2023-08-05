<#
    Classic Zone
#>
$GroupName    = (Get-PodeConfig).PSXi.Group1

Add-PodeWebPage -ArgumentList @($GroupName) -Group $($GroupName) -Name "$($GroupName) ESXi Host Table" -Title "$($GroupName) ESXi Host Inventory" -Icon 'server' -ScriptBlock {
    param($GroupName)

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
    $PSXiViews           = (Get-PodeConfig).PSXi.Views
    $SqlViewName         = switch -regex ($PSXiViews){ $GroupName { $_ } }
    $global:SqlTableName = "$($SqlViewName.Replace('view_',''))"
    $SqlNotesTableName   = "$($SqlViewName.Replace('view_',''))Notes"
    #endregion Defaults
    
    #region Breadcrumb
    Set-PodeWebBreadcrumb -Items @(
        New-PodeWebBreadcrumbItem -Name 'Home' -Url '/'
        New-PodeWebBreadcrumbItem -Name "$GroupName ESXi Host Inventory" -Url "/pages/PageName?value=$($GroupName) ESXi Hosts Table" -Active
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
                $i = $ii = 100
                $SqlViewName = $item
                $SqliteQuery  = "Select * from $($SqlViewName)"
                $FullDB       = Invoke-MySQLiteQuery -Path $global:PodeDB -Query $SqliteQuery
                [datetime]$Created = $FullDB.Created | Select-Last 1
                $VIServer     = $FullDB | Group-Object vCenterServer | Select-Object -ExpandProperty Name
                $Properties = (Get-PodeConfig).PSXi.TableHeader
            }
        }
        #endregion Get data from SQLite

        New-PodeWebContainer -NoBackground -Content @(

            if($MySQLiteDB){

                #region Summary
                New-PodeWebCard -Name Summary -DisplayName "Summary of $GroupName" -Content @(
                    New-PodeWebText -Value "Last update: $(Get-Date $Created -f 'yyyy-MM-dd HH:mm:ss') "  
                    New-PodeWebBadge -Colour Green -Value "$($VIServer.Count) vCenter"
                    $TotalCluster = $FullDB | Group-Object Cluster
                    New-PodeWebBadge -Colour Cyan -Value "$($TotalCluster.Count) Cluster"
                    $ESXiHosts = $FullDB | Group-Object HostName
                    New-PodeWebBadge -Colour Blue -Value "$($ESXiHosts.Count) ESXiHosts"
                    $VersionGroup = Invoke-MySQLiteQuery -Path $global:PodeDB -Query "Select Version, COUNT(Version) AS Count from $($SqlViewName) Group by Version"
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
                New-PodeWebForm -Id "Form$($GroupName)" -Name "Search for ESXiHost" -AsCard -ShowReset -ArgumentList @($Properties, $global:PodeDB, $SqlViewName) -ScriptBlock {
                    param($Properties, $global:PodeDB, $SqlViewName)
                    $SqliteQuery = "Select * from $($SqlViewName) Where HostName Like '%$($WebEvent.Data.Search)%' Order by vCenterServer"
                    Invoke-MySQLiteQuery -Path $global:PodeDB -Query $SqliteQuery | Out-PodeWebTable -Sort
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
                            param($Properties, $item, $global:PodeDB, $SqlNotesTableName, $Cluster)
                            $SqliteQuery = "Select * from $($SqlNotesTableName)"
                            Invoke-MySQLiteQuery -Path $global:PodeDB -Query $SqliteQuery
                        } -Compact -ArgumentList @($Properties, $item, $global:PodeDB, $SqlNotesTableName, $Cluster) -ScriptBlock {
                            param($Properties, $item, $global:PodeDB, $SqlNotesTableName, $Cluster)
                            $SqliteQuery = "Select * from $($SqlNotesTableName)"
                            Invoke-MySQLiteQuery -Path $global:PodeDB -Query $SqliteQuery
                        }
                        #endregion Table ESXiNotes

                        #region Add ESXiNotes
                        New-PodeWebForm -Id "$($GroupName)AddESXiNotes" -Name "Add Notes for ESXiHost" -ShowReset -AsCard -ArgumentList @($GroupName, $global:PodeDB, $SqlNotesTableName) -ScriptBlock {
                            param($GroupName, $global:PodeDB, $SqlNotesTableName)
                            $SqliteQuery = "INSERT INTO $($SqlNotesTableName) (HostName, Notes) VALUES ('$($WebEvent.Data.AddHostName)', '$($WebEvent.Data.Notes)')"
                            Invoke-MySQLiteQuery -Path $global:PodeDB -Query $SqliteQuery
                            Sync-PodeWebTable -Name "$($GroupName)TableESXiNotes"
                            Show-PodeWebToast -Message "Notes for $($WebEvent.Data.AddHostName) inserted"
                        } -Content @(
                            New-PodeWebTextbox -Name 'AddHostName' -DisplayName 'HostName' -Placeholder 'ESXiHost' -AutoComplete {
                                return @(Invoke-MySQLiteQuery -Path $global:PodeDB -Query "SELECT HostName FROM '$($global:SqlTableName)'").HostName
                            }
                            New-PodeWebTextbox -Name 'Notes' -Placeholder 'New Notes for this ESXiHost'
                        )
                        #endregion Add ESXiNotes

                        #region Remove ESXiNotes
                        New-PodeWebForm -Id "$($GroupName)RemoveESXiNotes" -Name "Remove Notes of ESXiHost" -ShowReset -AsCard -ArgumentList @($GroupName, $global:PodeDB, $SqlNotesTableName) -ScriptBlock {
                            param($GroupName, $global:PodeDB, $SqlNotesTableName)
                            $SqliteQuery = "DELETE FROM $($SqlNotesTableName) WHERE (HostName like '%$($WebEvent.Data.RemoveHostName)%')"
                            Invoke-MySQLiteQuery -Path $global:PodeDB -Query $SqliteQuery
                            Sync-PodeWebTable -Name "$($GroupName)TableESXiNotes"
                            Show-PodeWebToast -Message "Notes for $($WebEvent.Data.RemoveHostName) removed"
                        } -Content @(
                            New-PodeWebTextbox -Name 'RemoveHostName' -DisplayName 'HostName' -Placeholder 'ESXiHost' -AutoComplete {
                                return @(Invoke-MySQLiteQuery -Path $global:PodeDB -Query "SELECT HostName FROM '$($global:SqlTableName)'").HostName
                            }
                        )
                        #endregion Remove ESXiNotes

                    )

                )
            )

            New-PodeWebLine
            
            #region tables
            if($MySQLiteDB){
                #region VIServer
                foreach($item in $VIServer){
                    $i ++
                    $vCenter = (($item -split '\.')[0]).ToUpper()
                    $VICluster = $FullDB | Where-Object vCenterServer -match $item | Group-Object Cluster | Select-Object -ExpandProperty Name
                    $ESXiHosts = $FullDB | Where-Object vCenterServer -match $item | Group-Object HostName

                    New-PodeWebCard -Id "VC$($i)" -Name "VC$($i)" -DisplayName "vCenter «$($vCenter)» contains $($VICluster.count) Cluster, $($ESXiHosts.Count) ESXiHosts" -Content @(

                        foreach($Cluster in $VICluster){
                            $ii ++

                            #region Badge 
                            New-PodeWebText -Value "Cluster «$($Cluster)» contains:" -Style Italics
                            #New-PodeWebBadge -Colour Light -Value "$($Cluster)"
                            $ESXiHosts = $FullDB | Where-Object vCenterServer -match $item | Where-Object Cluster -match $Cluster | Group-Object HostName
                            New-PodeWebBadge -Colour Blue -Value "$($ESXiHosts.Count) ESXiHosts"

                            $VersionGroup = $FullDB | Where-Object vCenterServer -match $item | Where-Object Cluster -match $Cluster| Group-Object Version
                            for($i = 0; $i -lt $VersionGroup.count; $i++ ){
                                switch -Regex ($VersionGroup[$i].Name){
                                    '^6\.5'   {$Colour = 'Red'}
                                    '^6\.7'   {$Colour = 'Yellow'}
                                    '^7\.0'   {$Colour = 'Green'}
                                    default {$Colour = 'Dark'}
                                }
                                if($VersionGroup[$i].Count -gt 0){
                                    New-PodeWebBadge -Colour $Colour -Value "V$($VersionGroup[$i].Name) ($($VersionGroup[$i].Count))"
                                }
                            }
                            New-PodeWebLine
                            #endregion

                            New-PodeWebTable -Id "Table$($ii)" -Name "VC$($ii)" -DisplayName "Cluster $($Cluster)" -AsCard -SimpleSort -NoRefresh -NoExport -Click -DataColumn HostName -ClickScriptBlock{
                                param($Properties, $item, $global:PodeDB, $SqlViewName, $Cluster)
                                $SqliteQuery = "Select * from $($SqlViewName) Where (HostName = '$($WebEvent.Data.Value)')"
                                $Result = Invoke-MySQLiteQuery -Path $global:PodeDB -Query $SqliteQuery #-As Hashtable | Select-Object -ExpandProperty Values
                                foreach($item in $Result){ $Message = "$($Message), $($item)" }
                                Show-PodeWebToast -Title $($WebEvent.Data.Value) -Message $Message.TrimStart(', ') -Duration 900000
                            } -Compact -ArgumentList @($Properties, $item, $global:PodeDB, $SqlViewName, $Cluster) -ScriptBlock {
                                param($Properties, $item, $global:PodeDB, $SqlViewName, $Cluster)
                                $SqliteQuery = "Select * from $($SqlViewName) Where (vCenterServer Like '%$($item)%') And (Cluster = '$Cluster')"
                                Invoke-MySQLiteQuery -Path $global:PodeDB -Query $SqliteQuery | Select-Object $Properties
                            }

                        }
                    ) 
                }
                #endregion VIServer
            }
            #endregion tables
            
        )

    }else{
        New-PodeWebCard -Name 'Warning' -Content @(
            New-PodeWebAlert -Value "Could not find $($global:PodeDB)" -Type Warning
        )
    }

}
