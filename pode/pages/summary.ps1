Import-PodeWebStylesheet -Url 'psxi.css'

Add-PodeWebPage -Name 'Summary' -Title 'Summary' -Icon 'clipboard-check' -ScriptBlock {

    #region module
    if(-not(Get-InstalledModule -Name mySQLite -ea SilentlyContinue)){
        Install-Module -Name mySQLite -Force
        $Error.Clear()
    }
    if(-not(Get-Module -Name mySQLite)){ Import-Module -Name mySQLite }
    #endregion

    $i = 500
    $PodeRoot     = $($PSScriptRoot).Replace('pages','db')
    $PodeDB       = Join-Path $PodeRoot -ChildPath 'psxi.db'
    $SqlTableName = (Get-PodeConfig).PSXi.Tables #'cloud_summary', 'cloud_ESXiHosts'

    if(Test-Path $PodeDB){
        $TableExists = foreach($item in $SqlTableName){
            $SqliteQuery = "SELECT * FROM sqlite_master WHERE name like '$item'"
            Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
        }
        if(-not([String]::IsNullOrEmpty($TableExists))){

            New-PodeWebCard -Name 'Overall Summary' -Content @(
                
                #region VMware
                $SqliteQuery = "SELECT COUNT(VIServer) AS 'Total VIServer', SUM(CountOfHosts) AS 'Total Hosts', SUM(CountOfVMs) AS 'Total VMs' FROM cloud_summary"
                $cloud_summary = Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
    
                $SqliteQuery = "SELECT COUNT(VIServer) AS 'Total VIServer', SUM(CountOfHosts) AS 'Total Hosts', SUM(CountOfVMs) AS 'Total VMs' FROM classic_summary"
                $classic_summary = Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
                
                $TotalvCenter = $classic_summary.'Total VIServer' + $cloud_summary.'Total VIServer'
                New-PodeWebBadge -Colour Green -Value "$($TotalvCenter) vCenter"
                $ESXiHosts = $classic_summary.'Total Hosts' + $cloud_summary.'Total Hosts'
                New-PodeWebBadge -Colour Blue -Value "$($ESXiHosts) ESXiHosts"
                #endregion VMware

                #region Hyper-V
                $SqliteQuery = "SELECT COUNT(VIServer) AS 'Total VIServer', SUM(CountOfHosts) AS 'Total Hosts', SUM(CountOfVMs) AS 'Total VMs' FROM hyperv_summary"
                $hyperv_summary = Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
                
                $SCVMHosts = $hyperv_summary.'Total Hosts'
                New-PodeWebBadge -Colour Yellow -Value "$($hyperv_summary.'Total VIServer') VMMServer"
                New-PodeWebBadge -Colour Red -Value "$($SCVMHosts) Hyper-V Hosts"
                #endregion Hyper-V

                $VMs = $classic_summary.'Total VMs' + $cloud_summary.'Total VMs' + $hyperv_summary.'Total VMs'
                New-PodeWebBadge -Colour Light -Value "$($VMs) VMs"

                $BarColors = @('#32CD32','#0096FF','#FF5733')
                New-PodeWebGrid -Cells @(

                    New-PodeWebCell -Id 'VIServer' -Width '30%' -Content @(
                        New-PodeWebChart -Name "Overall Summary VIServer" -ArgumentList @($cloud_summary, $classic_summary, $hyperv_summary) -Type Bar -Colours $BarColors -Height 300px -NoRefresh -ScriptBlock {
                            param($cloud_summary, $classic_summary, $hyperv_summary)
                            @{
                                Key    = 'VIServer'
                                Values = @(
                                    @{
                                        Key   = 'Classic'
                                        Value = $classic_summary.'Total VIServer'
                                    }
                                    @{
                                        Key   = 'Cloud'
                                        Value = $cloud_summary.'Total VIServer'
                                    }
                                    @{
                                        Key   = 'Hyper-V'
                                        Value = $hyperv_summary.'Total VIServer'
                                    }
                                )
                            }
                        }
                    )

                    New-PodeWebCell -Id 'Hosts' -Width '30%' -Content @(
                        New-PodeWebChart -Name "Overall Summary Hosts" -ArgumentList @($cloud_summary, $classic_summary, $hyperv_summary) -Type Bar -Colours $BarColors -Height 300px -NoRefresh -ScriptBlock {
                            param($cloud_summary, $classic_summary, $hyperv_summary)
                            @{
                                Key    = 'Hosts'
                                Values = @(
                                    @{
                                        Key   = 'Classic'
                                        Value = $classic_summary.'Total Hosts'
                                    }
                                    @{
                                        Key   = 'Cloud'
                                        Value = $cloud_summary.'Total Hosts'
                                    }
                                    @{
                                        Key   = 'Hyper-V'
                                        Value = $hyperv_summary.'Total Hosts'
                                    }
                                )
                            }
                        }
                    )

                    New-PodeWebCell -Id 'VMs' -Width '30%' -Content @(
                        New-PodeWebChart -Name "Overall Summary VMs" -ArgumentList @($cloud_summary, $classic_summary, $hyperv_summary) -Type Bar -Colours $BarColors -Height 300px -NoRefresh -ScriptBlock {
                            param($cloud_summary, $classic_summary, $hyperv_summary)
                            @{
                                Key    = 'VMs'
                                Values = @(
                                    @{
                                        Key   = 'Classic'
                                        Value = $classic_summary.'Total VMs'
                                    }
                                    @{
                                        Key   = 'Cloud'
                                        Value = $cloud_summary.'Total VMs'
                                    }
                                    @{
                                        Key   = 'Hyper-V'
                                        Value = $hyperv_summary.'Total VMs'
                                    }
                                )
                            }
                        }
                    )

                )

            )
    
            # New-PodeWebForm -Id "Form$($i)" -Name "Search for ESXiHost" -AsCard -ShowReset -ArgumentList @($PodeDB) -ScriptBlock {
            #     param($PodeDB)
            #     $SqliteQuery = "Select * from classic_ESXiHosts Where HostName Like '%$($WebEvent.Data.Search)%'"
            #     $Result = Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
            #     if([String]::IsNullOrEmpty($Result)){
            #         $SqliteQuery = "Select * from cloud_ESXiHosts Where HostName Like '%$($WebEvent.Data.Search)%'"
            #         $Result = Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
            #     }
            #     $Properties = (Get-PodeConfig).PSXi.TableHeader + "vCenterServer"
            #     $Result | Select-Object $Properties | Out-PodeWebTable
            # } -Content @(
            #     New-PodeWebTextbox -Id "Search$($i)" -Name 'Search' -DisplayName 'HostName' -Type Text -NoForm -Width '1000px'
            # )
    
            New-PodeWebGrid -Cells @(
    
                if(Test-Path $PodeDB){
                    $SqlTableName = 'classic_summary', 'cloud_summary', 'hyperv_summary'
                    $Properties   = @('VIServer', 'Hosts', 'VMs')

                    foreach($item in $SqlTableName){

                        $i ++
                        $SqliteQuery = "SELECT COUNT(VIServer) AS 'VIServer', SUM(CountOfHosts) AS 'Hosts', SUM(CountOfVMs) AS 'VMs' FROM $item"

                        switch -Regex ($item){
                            'cloud' {
                                $DisplayName = 'Cloud'
                                $summary = Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
                            }
                            'classic' {
                                $DisplayName = 'Classic'
                                $summary = Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
                            }
                            'hyperv' {
                                $DisplayName = 'Hyper-V'
                                $summary = Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery
                            }
                        }
    
                        New-PodeWebCell -Width '30%' -Content @(

                            New-PodeWebCard  -Id "Chart$($i)" -Name "Chart$($i)" -DisplayName "$($DisplayName) Summary" -Content @(

                                if($DisplayName -match 'Hyper-V'){
                                    New-PodeWebBadge -Colour Green -Value "$($summary.VIServer) VMMServer"
                                }else{
                                    New-PodeWebBadge -Colour Green -Value "$($summary.VIServer) VIServer"
                                }
                                New-PodeWebBadge -Colour Blue  -Value "$($summary.Hosts) Hosts"
                                New-PodeWebBadge -Colour Light -Value "$($summary.VMs) VMs"

                                New-PodeWebChart -Name "$DisplayName Summary" -ArgumentList @($summary) -Type Bar -Colours $BarColors -Height 250px -NoRefresh -ScriptBlock {
                                    param($summary)
                                    $summary | ConvertTo-PodeWebChartData -LabelProperty 'VIServer' -DatasetProperty @('Hosts', 'VMs')
                                }

                                $SqliteQuery = "Select VIServer, CountOfHosts AS 'Hosts', CountOfVMs AS 'VMs' from $($item)"
                                New-PodeWebTable -Id "Table$($i)" -Name "Summary$($i)" -DisplayName "$($DisplayName) Summary" -SimpleSort -Click -NoExport -NoRefresh -Compact -ArgumentList @($PodeDB,$SqliteQuery,$Properties) -ScriptBlock {
                                    param($PodeDB,$SqliteQuery,$Properties)
                                    Invoke-MySQLiteQuery -Path $PodeDB -Query $SqliteQuery | Select-Object $Properties
                                }                     

                            )
    
                        )
                    }
                }
            )
        }else{
            New-PodeWebCard -Name 'Warning' -Content @(
                New-PodeWebAlert -Value "Could not find table in $($PodeDB)" -Type Warning
                New-PodeWebAlert -Value "Please upload CSV-files ($($SqlTableName))" -Type Important
                #New-PodeWebAlert -Value 'And restart the server' -Type Important
            )
        }
    
    }else{
        New-PodeWebCard -Name 'Warning' -Content @(
            New-PodeWebAlert -Value "Could not find $($PodeDB)" -Type Warning
        )
    }

}
