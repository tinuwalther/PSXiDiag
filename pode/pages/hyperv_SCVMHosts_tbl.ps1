<#
    Cloud Zone
#>
Import-PodeWebStylesheet -Url 'psxi.css'

$GroupName = (Get-PodeConfig).PSXi.Group3
$PageName  = "1. $($GroupName) Hosts"
$PageTitle = "1. $($GroupName) Host Inventory"

Add-PodeWebPage -Group $($GroupName) -Name $PageName -Title $PageTitle -Icon 'cloud' -ArgumentList @($GroupName, $PageName, $PageTitle) -ScriptBlock {
    param($GroupName, $PageName, $PageTitle)

    #region module
    if(-not(Get-InstalledModule -Name mySQLite -ea SilentlyContinue)){
        Install-Module -Name mySQLite -Force
        $Error.Clear()
    }
    if(-not(Get-Module -Name mySQLite)){ Import-Module -Name mySQLite }
    #endregion

    #region Defaults
    $NewGroupName        = $GroupName.replace('-','')
    $PodeRoot            = $($PSScriptRoot).Replace('pages','db')
    $global:PodeDB       = Join-Path $PodeRoot -ChildPath 'psxi.db'
    $PSXiViews           = (Get-PodeConfig).PSXi.Views
    $SqlViewName         = switch -regex ($PSXiViews){ $NewGroupName { $_ } }
    $global:SqlTableName = "$($SqlViewName.Replace('view_',''))"
    $SqlNotesTableName   = "$($SqlViewName.Replace('view_',''))Notes"
    #endregion Defaults
    
    #region Breadcrumb
    Set-PodeWebBreadcrumb -Items @(
        New-PodeWebBreadcrumbItem -Name 'Home' -Url '/'
        New-PodeWebBreadcrumbItem -Name $PageTitle -Url "/pages/PageName?value=$($PageTitle)" -Active
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
                $i =  1000 
                $ii = 1000
                $SqlViewName = $item
                $SqliteQuery  = "Select * from $($SqlViewName)"
                $FullDB       = Invoke-MySQLiteQuery -Path $global:PodeDB -Query $SqliteQuery
                [datetime]$Created = $FullDB.Created | Select-Last 1
                $VMMServer  = $FullDB | Group-Object VMMServer | Select-Object -ExpandProperty Name
                $VMMCluster = $FullDB | Group-Object Cluster | Select-Object -ExpandProperty Name
                $Properties = (Get-PodeConfig).PSXi.hvHostHeader
            }
        }
        #endregion Get data from SQLite
        
        New-PodeWebContainer -NoBackground -Content @(

            if($MySQLiteDB){

                #region Summary
                New-PodeWebCard -Name Summary -DisplayName "Summary of $GroupName Hosts" -Content @(
                    New-PodeWebText -Value "Last update: $(Get-Date $Created -f 'yyyy-MM-dd HH:mm:ss') "  
                    New-PodeWebBadge -Colour Green -Value "$($VMMServer.Count) VMMServer"
                    $TotalCluster = $FullDB | Group-Object Cluster
                    New-PodeWebBadge -Colour Cyan -Value "$($TotalCluster.Count) Cluster"
                    $SCVMHosts = $FullDB | Group-Object HostName
                    New-PodeWebBadge -Colour Blue -Value "$($SCVMHosts.Count) Hosts"
                    $VersionGroup = Invoke-MySQLiteQuery -Path $global:PodeDB -Query "Select Version, COUNT(Version) AS Count from $($SqlViewName) Group by Version"
                    for($i = 0; $i -lt $VersionGroup.count; $i++ ){
                        # "$($SqlViewName) : $($VersionGroup[$i].Version) : $($VersionGroup[$i].Count)" | Out-Default
                        switch -Regex ($VersionGroup[$i].Version){
                            '17763'   {$Colour = 'Green'}
                            '14393'   {$Colour = 'Yellow'}
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
                New-PodeWebForm -Id "Form$($GroupName)" -Name "Search for Host" -AsCard -ShowReset -ArgumentList @($Properties, $global:PodeDB, $SqlViewName) -ScriptBlock {
                    param($Properties, $global:PodeDB, $SqlViewName)
                    $SqlFields = [string]$Properties -replace '\s', ','
                    $SqliteQuery = "Select $SqlFields from $($SqlViewName) Where HostName Like '%$($WebEvent.Data.Search)%' Order by Cluster"
                    Invoke-MySQLiteQuery -Path $global:PodeDB -Query $SqliteQuery | Out-PodeWebTable -Sort
                } -Content @(
                    New-PodeWebTextbox -Id "Search$($GroupName)" -Name 'Search' -DisplayName 'HostName' -Type Text -NoForm -Width '450px' -Placeholder 'Enter a HostName or leave it empty to load all Hosts' -CssClass 'no-form'
                )
                #endregion Search

            }

            New-PodeWebAccordion -Mode Collapsed -Bellows @(

                New-PodeWebBellow -Name "$GroupName Hosts Notes" -Content @(

                    New-PodeWebContainer -NoBackground -Content @(

                        #region Table SCVMHosts
                        New-PodeWebTable -Id "$($GroupName)TblNotes" -Name "$($GroupName)TableSCVMHosts" -DisplayName "$($GroupName) Hosts Notes" -AsCard -SimpleSort -NoRefresh -NoExport -Click -DataColumn HostName -ClickScriptBlock{
                            param($Properties, $item, $global:PodeDB, $SqlNotesTableName, $Cluster)
                            $SqliteQuery = "Select * from $($SqlNotesTableName)"
                            Invoke-MySQLiteQuery -Path $global:PodeDB -Query $SqliteQuery
                        } -Compact -ArgumentList @($Properties, $item, $global:PodeDB, $SqlNotesTableName, $Cluster) -ScriptBlock {
                            param($Properties, $item, $global:PodeDB, $SqlNotesTableName, $Cluster)
                            $SqliteQuery = "Select * from $($SqlNotesTableName)"
                            Invoke-MySQLiteQuery -Path $global:PodeDB -Query $SqliteQuery
                        }
                        #endregion Table SCVMHosts

                        #region Add SCVMHosts
                        New-PodeWebForm -Id "$($GroupName)AddSCVMHosts" -Name "Add/Update Notes for $($GroupName) Host" -ShowReset -AsCard -ArgumentList @($GroupName, $global:PodeDB, $SqlNotesTableName) -ScriptBlock {
                            param($GroupName, $global:PodeDB, $SqlNotesTableName)
                            $HostExists = Invoke-MySQLiteQuery -Path $global:PodeDB -Query "SELECT HostName from $($SqlNotesTableName) WHERE HostName = '$($WebEvent.Data.AddHostName.Trim())'"
                            if([String]::IsNullOrEmpty($HostExists)){
                                # ADD
                                $SqliteQuery = "INSERT INTO $($SqlNotesTableName) (HostName, Notes) VALUES ('$($WebEvent.Data.AddHostName.Trim())', '$($WebEvent.Data.Notes.Trim())')"
                                Invoke-MySQLiteQuery -Path $global:PodeDB -Query $SqliteQuery
                                Sync-PodeWebTable -Name "$($GroupName)TableSCVMHosts"
                                Show-PodeWebToast -Message "Notes for $($WebEvent.Data.AddHostName) inserted"
                            }else{
                                # UPDATE
                                $SqliteQuery = "UPDATE $($SqlNotesTableName) SET Notes='$($WebEvent.Data.Notes.Trim())' WHERE HostName = '$($WebEvent.Data.AddHostName.Trim())'"
                                Invoke-MySQLiteQuery -Path $global:PodeDB -Query $SqliteQuery
                                Sync-PodeWebTable -Name "$($GroupName)TableSCVMHosts"
                                Show-PodeWebToast -Message "Notes for $($WebEvent.Data.AddHostName) updated"
                            }
                        } -Content @(
                            New-PodeWebTextbox -Name 'AddHostName' -DisplayName 'HostName' -Placeholder "$($GroupName) Host" -AutoComplete {
                                return @(Invoke-MySQLiteQuery -Path $global:PodeDB -Query "SELECT HostName FROM '$($global:SqlTableName)'").HostName
                            }
                            New-PodeWebTextbox -Name 'Notes' -Placeholder "New Notes for this $($GroupName) Host"
                        )
                        #endregion Add SCVMHosts

                        #region Remove SCVMHosts
                        New-PodeWebForm -Id "$($GroupName)RemoveSCVMHosts" -Name "Remove Notes of $($GroupName) Host" -ShowReset -AsCard -ArgumentList @($GroupName, $global:PodeDB, $SqlNotesTableName) -ScriptBlock {
                            param($GroupName, $global:PodeDB, $SqlNotesTableName)
                            $SqliteQuery = "DELETE FROM $($SqlNotesTableName) WHERE (HostName like '%$($WebEvent.Data.RemoveHostName)%')"
                            Invoke-MySQLiteQuery -Path $global:PodeDB -Query $SqliteQuery
                            Sync-PodeWebTable -Name "$($GroupName)TableSCVMHosts"
                            Show-PodeWebToast -Message "Notes for $($WebEvent.Data.RemoveHostName) removed"
                        } -Content @(
                            New-PodeWebTextbox -Name 'RemoveHostName' -DisplayName 'HostName' -Placeholder "$($GroupName) Hosts" -AutoComplete {
                                return @(Invoke-MySQLiteQuery -Path $global:PodeDB -Query "SELECT HostName FROM '$($global:SqlTableName)'").HostName
                            }
                        )
                        #endregion Remove SCVMHosts

                    )

                )
            )

        )
        
        #region tables
        if($MySQLiteDB){
            New-PodeWebContainer -NoBackground -Content @(

                #region Tabs
                New-PodeWebTabs -Tabs @(
                    foreach($item in $VMMCluster){

                        $i ++
                        # $vCenter = (($item -split '\.')[0]).ToUpper()
                        # $VICluster = $FullDB | Where-Object vCenterServer -match $item | Group-Object Cluster | Select-Object -ExpandProperty Name
                        $SCVMHosts = $FullDB | Where-Object Cluster -match $item | Group-Object HostName
                        
                        New-PodeWebTab -Id "Tab$($i)" -Name "Cluster $($item)" -Layouts @(
                            
                            #region Badge
                            New-PodeWebCard -NoTitle -NoHide -Content @(
                                New-PodeWebText -Value "Cluster «$($item)» contains:" -Style Bold
                                #New-PodeWebBadge -Colour Cyan -Value "$($VICluster.count) Cluster"
                                New-PodeWebBadge -Colour Blue -Value "$($SCVMHosts.Count) Hosts"
                            )
                            #endregion Badge

                            # foreach($Cluster in $VICluster){
                            #     $ii ++

                            #     #region Badge
                            #     New-PodeWebParagraph -Elements @(
                            #         New-PodeWebText -Value "Cluster «$($Cluster)» contains:" -Style Italics
                            #         $ESXiHosts = $FullDB | Where-Object vCenterServer -match $item | Where-Object Cluster -match $Cluster | Group-Object HostName
                            #         New-PodeWebBadge -Colour Blue -Value "$($ESXiHosts.Count) ESXiHosts"
                            #         $FullDB | Where-Object vCenterServer -match $item | Where-Object Cluster -match $Cluster| Group-Object Version | ForEach-Object {
                            #             switch -Regex ($_.Name){
                            #                 '^7\.0'   {$Colour = 'Green'}
                            #                 '^6\.7'   {$Colour = 'Yellow'}
                            #                 '^6\.5'   {$Colour = 'Red'}
                            #                 default {$Colour = 'Dark'}
                            #             }
                            #             if($_.count -gt 0){
                            #                 New-PodeWebBadge -Colour $Colour -Value "V$($_.Name) ($($_.Count))"
                            #             }
                            #         }
                            #     )
                            #     #endregion Badge
    
                            #     #region add table
                            #     New-PodeWebTable -Id "Table$($ii)" -Name "VC$($ii)" -DisplayName "Cluster $($Cluster)" -AsCard -SimpleSort -NoExport -NoRefresh -Click -DataColumn HostName -ClickScriptBlock{
                            #         param($Properties, $item, $global:PodeDB, $SqlViewName, $Cluster)
                            #         $SqliteQuery = "Select * from $($SqlViewName) Where (HostName = '$($WebEvent.Data.Value)')"
                            #         $Result = Invoke-MySQLiteQuery -Path $global:PodeDB -Query $SqliteQuery #-As Hashtable | Select-Object -ExpandProperty Values
                            #         foreach($item in $Result){ $Message = "$($Message), $($item)" }
                            #         Show-PodeWebToast -Title $($WebEvent.Data.Value) -Message $Message.TrimStart(', ') -Duration 900000
                            #     } -Compact -ArgumentList @($Properties, $item, $global:PodeDB, $SqlViewName, $Cluster) -ScriptBlock {
                            #         param($Properties, $item, $global:PodeDB, $SqlViewName, $Cluster)
                            #         $SqliteQuery = "Select * from $($SqlViewName) Where (vCenterServer Like '%$($item)%') And (Cluster = '$Cluster')"
                            #         Invoke-MySQLiteQuery -Path $global:PodeDB -Query $SqliteQuery | Select-Object $Properties
                            #     }
                            #     #endregion add table

                            # }
                        )
                    }
                )
                #endregion
            )
        }
        #endregion tables
        
    }else{
        New-PodeWebCard -Name 'Warning' -Content @(
            New-PodeWebAlert -Value "Could not find $($global:PodeDB)" -Type Warning
        )
    }

}