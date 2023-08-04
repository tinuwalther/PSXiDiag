<#
    Classic Zone
#>
$GroupName = (Get-PodeConfig).PSXi.Group1
Add-PodeWebPage -Group $($GroupName) -Name "$($GroupName) ESXi Host Table" -Title "$($GroupName) ESXi Host Inventory" -Icon 'server' -ArgumentList $GroupName -ScriptBlock {
    param($GroupName)
    #region module
    if(-not(Get-InstalledModule -Name mySQLite -ea SilentlyContinue)){
        Install-Module -Name mySQLite -Force
        $Error.Clear()
    }
    if(-not(Get-Module -Name mySQLite)){ Import-Module -Name mySQLite }
    #endregion
    
    Set-PodeWebBreadcrumb -Items @(
        New-PodeWebBreadcrumbItem -Name 'Home' -Url '/'
        New-PodeWebBreadcrumbItem -Name "$GroupName ESXi Host Inventory" -Url "/pages/PageName?value=$($GroupName) ESXi Hosts Table" -Active
    )

    $PodeRoot     = $($PSScriptRoot).Replace('pages','db')
    $PodeDB       = Join-Path $PodeRoot -ChildPath 'psxi.db'
    $PSXiTables   = (Get-PodeConfig).PSXi.Tables #'classic_summary', 'classic_ESXiHosts'
    $SqlTableName = switch -regex ($PSXiTables){ $GroupName { $_ } }

    if(Test-Path $PodeDB){

        #region Get data from SQLite
        $TableExists = foreach($item in $SqlTableName){
            $SqliteQuery = "SELECT * FROM sqlite_master WHERE name like '$item'"
            Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
        }

        if([String]::IsNullOrEmpty($TableExists)){
            New-PodeWebCard -Name 'Warning' -Content @(
                New-PodeWebAlert -Value "Could not find table in $($PodeDB)" -Type Warning
                New-PodeWebAlert -Value "Please upload CSV-files ($($SqlTableName))" -Type Important
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
                $i = $ii = 100
                $SqlTableName = $item #'classic_ESXiHosts'
                $SqliteQuery  = "Select * from $($SqlTableName)"
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
                $VersionGroup = Invoke-MySQLiteQuery -Path $PodeDB -Query "Select Version, COUNT(Version) AS Count from $($SqlTableName) Group by Version"
                for($i = 0; $i -lt $VersionGroup.count; $i++ ){
                    # "$($SqlTableName) : $($VersionGroup[$i].Version) : $($VersionGroup[$i].Count)" | Out-Default
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
            New-PodeWebForm -Id "Form$($i)" -Name "Search for ESXiHost" -AsCard -ShowReset -ArgumentList @($Properties, $PodeDB, $SqlTableName) -ScriptBlock {
                param($Properties, $PodeDB, $SqlTableName)
                $SqliteQuery = "Select * from $($SqlTableName) Where HostName Like '%$($WebEvent.Data.Search)%' Order by vCenterServer"
                Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery | Out-PodeWebTable -Sort
            } -Content @(
                New-PodeWebTextbox -Id "Search$($i)" -Name 'Search' -DisplayName 'HostName' -Type Text -NoForm -Width '400px' -Placeholder 'Enter a HostName or leave it empty to load all Hosts'
            )
            #endregion Search
        }

        New-PodeWebAccordion -Bellows @(

            New-PodeWebBellow -Name "All $GroupName ESXiHosts" -Content @(

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

                                New-PodeWebTable -Id "Table$($ii)" -Name "VC$($ii)" -DisplayName "Cluster $($Cluster)" -AsCard -SimpleSort -NoExport -Click -DataColumn HostName -ClickScriptBlock{
                                    param($Properties, $item, $PodeDB, $SqlTableName, $Cluster)
                                    $SqliteQuery = "Select * from $($SqlTableName) Where (HostName = '$($WebEvent.Data.Value)')"
                                    $Result = Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery #-As Hashtable | Select-Object -ExpandProperty Values
                                    foreach($item in $Result){ $Message = "$($Message), $($item)" }
                                    Show-PodeWebToast -Title $($WebEvent.Data.Value) -Message $Message.TrimStart(', ') -Duration 900000
                                } -Compact -ArgumentList @($Properties, $item, $PodeDB, $SqlTableName, $Cluster) -ScriptBlock {
                                    param($Properties, $item, $PodeDB, $SqlTableName, $Cluster)
                                    $SqliteQuery = "Select * from $($SqlTableName) Where (vCenterServer Like '%$($item)%') And (Cluster = '$Cluster')"
                                    Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery | Select-Object $Properties
                                }

                            }
                        ) 
                    }
                    #endregion VIServer
                }
            
            )
            New-PodeWebBellow -Name "$GroupName ESXiHosts Notes" -Content @(

                New-PodeWebContainer -NoBackground -Content @(

                    $SqlTableName = "$($SqlTableName.Replace('view_',''))Notes"

                    #region Table ESXiNotes
                    New-PodeWebTable -Id TblNotes -Name TableESXiNotes -DisplayName "ESXi Notes" -AsCard -SimpleSort -NoRefresh -NoExport -Click -DataColumn HostName -ClickScriptBlock{
                        param($Properties, $item, $PodeDB, $SqlTableName, $Cluster)
                        $SqliteQuery = "Select * from $($SqlTableName)"
                        Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery #-As Hashtable | Select-Object -ExpandProperty Values
                        # foreach($item in $Result){ $Message = "$($Message), $($item)" }
                        #  Show-PodeWebToast -Title $($WebEvent.Data.Value) -Message $Message.TrimStart(', ') -Duration 900000
                    } -Compact -ArgumentList @($Properties, $item, $PodeDB, $SqlTableName, $Cluster) -ScriptBlock {
                        param($Properties, $item, $PodeDB, $SqlTableName, $Cluster)
                        $SqliteQuery = "Select * from $($SqlTableName)"
                        Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery #| Select-Object $Properties
                    }
                    #endregion Table ESXiNotes

                    #region Add ESXiNotes
                    New-PodeWebForm -Id AddESXiNotes -Name "Add Notes for ESXiHost" -ShowReset -AsCard -ArgumentList @($PodeDB, $SqlTableName) -ScriptBlock {
                        param($PodeDB, $SqlTableName)
                        $SqliteQuery = "INSERT INTO $($SqlTableName) (HostName, Notes) VALUES ('$($WebEvent.Data.HostName)', '$($WebEvent.Data.Notes)')"
                        Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
                        Sync-PodeWebTable -Name 'TableESXiNotes'
                        Show-PodeWebToast -Message "Notes for $($WebEvent.Data.HostName) inserted"
                    } -Content @(
                        New-PodeWebTextbox -Name 'HostName' -Placeholder 'ESXiHost'
                        New-PodeWebTextbox -Name 'Notes'    -Placeholder 'New Notes for this ESXiHost'
                    )
                    #endregion Add ESXiNotes

                    #region Remove ESXiNotes
                    New-PodeWebForm -Id RemoveESXiNotes -Name "Remove Notes of ESXiHost" -ShowReset -AsCard -ArgumentList @($PodeDB, $SqlTableName) -ScriptBlock {
                        param($PodeDB, $SqlTableName)
                        $SqliteQuery = "DELETE FROM $($SqlTableName) WHERE (HostName like '%$($WebEvent.Data.HostName)%')"
                        Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
                        Sync-PodeWebTable -Name 'TableESXiNotes'
                        Show-PodeWebToast -Message "Notes for $($WebEvent.Data.HostName) removed"
                    } -Content @(
                        New-PodeWebTextbox -Name 'HostName' -Placeholder 'ESXiHost'
                    )
                    #endregion Remove ESXiNotes

                )

            )
        )

    }else{
        New-PodeWebCard -Name 'Warning' -Content @(
            New-PodeWebAlert -Value "Could not find $($PodeDB)" -Type Warning
        )
    }

}
