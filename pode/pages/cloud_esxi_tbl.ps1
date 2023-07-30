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

    Set-PodeWebBreadcrumb -Items @(
        New-PodeWebBreadcrumbItem -Name 'Home' -Url '/'
        New-PodeWebBreadcrumbItem -Name "$GroupName ESXi Host Inventory" -Url "/pages/PageName?value=$($GroupName) ESXi Hosts Table" -Active
    )
    
    $PodeRoot = $($PSScriptRoot).Replace('pages','db')
    $PodeDB   = Join-Path $PodeRoot -ChildPath 'psxi.db'
    $PSXiTables   = (Get-PodeConfig).PSXi.Tables #'cloud_summary', 'cloud_ESXiHosts'
    $SqlTableName = switch -regex ($PSXiTables){ $GroupName { $_ } }

    if(Test-Path $PodeDB){

        New-PodeWebContainer -NoBackground -Content @(

            $TableExists = foreach($item in $SqlTableName){
                $SqliteQuery = "SELECT * FROM sqlite_master WHERE name like '$item'"
                Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
            }
            if([String]::IsNullOrEmpty($TableExists)){
                New-PodeWebCard -Name 'Warning' -Content @(
                    New-PodeWebAlert -Value "Could not find table in $($PodeDB)" -Type Warning
                    New-PodeWebAlert -Value "Please upload CSV-files ($($SqlTableName))" -Type Important
                )
            }else{
                $MySQLiteDB   = Open-MySQLiteDB -Path $PodeDB
                if([String]::IsNullOrEmpty($MySQLiteDB)){
                    New-PodeWebCard -Name 'Warning' -Content @(
                        New-PodeWebAlert -Value "Could not connect to $($PodeDB)" -Type Warning
                    )
                }else{
                    $i = $ii = 200
                    $SqlTableName = 'cloud_ESXiHosts'
                    $SqliteQuery  = "Select * from $($SqlTableName)"
                    $FullDB       = Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
                    [datetime]$Created = $FullDB.Created | Select-Last 1
                    $VIServer     = $FullDB | Group-Object vCenterServer | Select-Object -ExpandProperty Name
                    $Properties = (Get-PodeConfig).PSXi.TableHeader

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
                    #endregion

                    #region Search
                    New-PodeWebForm -Id "Form$($i)" -Name "Search for ESXiHost" -AsCard -ShowReset -ArgumentList @($Properties, $PodeDB, $SqlTableName) -ScriptBlock {
                        param($Properties, $PodeDB, $SqlTableName)
                        $SqliteQuery = "Select * from $($SqlTableName) Where HostName Like '%$($WebEvent.Data.Search)%'"
                        $sProperties = @('vCenterServer')
                        $sProperties += $Properties
                        Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery | Select-Object $sProperties | Out-PodeWebTable
                    } -Content @(
                        New-PodeWebTextbox -Id "Search$($i)" -Name 'Search' -DisplayName 'HostName' -Type Text -NoForm -Width '400px' -Placeholder 'Enter a HostName or leave it empty to load all Hosts'
                    )
                    #endregion

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
                                    # New-PodeWebLine
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
                                    # New-PodeWebLine
                                    #endregion
        
                                    New-PodeWebTable -Id "Table$($ii)" -Name "VC$($ii)" -DisplayName "Cluster $($Cluster)" -AsCard -SimpleSort -NoExport -NoRefresh -Click -DataColumn HostName -ClickScriptBlock{
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
                    )
                    #endregion

                }
            }

        ) 
        
    }else{
        New-PodeWebCard -Name 'Warning' -Content @(
            New-PodeWebAlert -Value "Could not find $($PodeDB)" -Type Warning
        )
    }

}