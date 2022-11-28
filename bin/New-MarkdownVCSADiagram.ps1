<#
.SYNOPSIS
    New-MarkdownVCSADiagram.ps1

.DESCRIPTION
    New-MarkdownVCSADiagram - Create a Mermaid Class Diagram.

.PARAMETER InputObject
    Specify a valid InputObject.
    
.PARAMETER RelationShip
    Specify a valid RelationShip.
    
.PARAMETER Title
    Specify a valid Title for the Website.
    
.PARAMETER Html
    Switch, if omitted the Output is saved as Markdown-File else as HTML-File.
    
.EXAMPLE
    .\New-MarkdownVCSADiagram.ps1 -InputObject (Import-Csv -Path ..\data\inventory.csv -Delimiter ';') -Title 'Markdown ESXiHost Inventory'

    Import-Csv with the default Delimiter and create the Mermaid-Diagram with the content of the CSV and the Title 'Markdown ESXiHost Inventory' as Markdown.

.EXAMPLE
    .\New-MarkdownVCSADiagram.ps1 -InputObject (Get-Content ..\data\Inventory.json | ConvertFrom-Json) -Title 'Markdown ESXiHost Inventory' -Title 'ESXiHost Inventory'

    Import from a JSON-File and create the Mermaid-Diagram with the content of the CSV and the Title 'HTML ESXiHost Inventory' as Html.

#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [Object]$InputObject,

    [Parameter(Mandatory=$false)]
    [String]$RelationShip = '--',

    [Parameter(Mandatory=$true)]
    [String]$Title,

    [Parameter(Mandatory=$false)]
    [Switch]$Html
)


begin{    
    $StartTime = Get-Date
    $function = $($MyInvocation.MyCommand.Name)
    foreach($item in $PSBoundParameters.keys){
        $params = "$($params) -$($item) $($PSBoundParameters[$item])"
    }
    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', "$($function)$($params)" -Join ' ')

    $vcNo = 0; $ClusterNo = 0; $ModelNo = 0
    $Page = $($MyInvocation.MyCommand.Name) -replace '.ps1'

    $OutFile = Join-Path -Path $($PSScriptRoot).Trim('bin') -ChildPath "$($Title).md"
    Write-Verbose $OutFile
}

process{

    #Fields = HostName;Version;Manufacturer;Model;vCenterServer;Cluster;PhysicalLocation;ConnectionState

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Process ]', $function -Join ' ')

    try{

        #region Markdown Header
        "# $($Header) - $($Title)`n" | Set-Content $OutFile -Encoding utf8 -Force
        #endregion

        #region vCenterServer Nav Links
        $GroupVC = $InputObject | Group-Object vCenterServer | Select-Object -ExpandProperty Name
        $GroupVC | ForEach-Object {
            $vCenter = $($_).Split('.')[0]
            if(-not([String]::IsNullOrEmpty($vCenter))){
                " - [vCenter $($vCenter)](`#vcenter-$(($vCenter).ToLower()))" | Add-Content $OutFile -Encoding utf8
            }
        }
        #endregion

        #region Group vCenter
        $GroupVC | ForEach-Object {

            $vcNo ++
            $vCenter = $($_).Split('.')[0]
            if(-not([String]::IsNullOrEmpty($vCenter))){
                Write-Verbose "vCenter: $($_)"

                #region section header
                "---`n" | Add-Content $OutFile -Encoding utf8
                "## [vCenter $($vCenter)](https://$($_)/ui)`n" | Add-Content $OutFile -Encoding utf8
                "---`n" | Add-Content $OutFile -Encoding utf8
        
                "````````mermaid" | Add-Content $OutFile -Encoding utf8
                "classDiagram"    | Add-Content $OutFile -Encoding utf8
                #endregion

                #region Group Cluster
                $InputObject | Where-Object vCenterServer -match $_ | Group-Object Cluster | Select-Object -ExpandProperty Name | ForEach-Object {
                    if(-not([String]::IsNullOrEmpty($_))){

                        Write-Verbose "Cluster: $($_)"

                        $ClusterNo ++
                        $RootCluster = $_
                        $FixCluster  = $RootCluster -replace '-'

                        "VC$($vcNo)_$($vCenter) $($RelationShip) VC$($vcNo)C$($ClusterNo)_$($FixCluster)" | Add-Content $OutFile -Encoding utf8
                        "VC$($vcNo)_$($vCenter) : + $($RootCluster)" | Add-Content $OutFile -Encoding utf8
        
                        #region Group Model
                        $InputObject | Where-Object vCenterServer -match $vCenter | Where-Object Cluster -match $RootCluster | Group-Object Model | Select-Object -ExpandProperty Name | ForEach-Object {
                            
                            Write-Verbose "Model: $($_)"

                            $ModelNo ++
                            $RootModel = $_
                            $FixModel  = $RootModel -replace '-'

                            "VC$($vcNo)C$($ClusterNo)_$($FixCluster) : + $($RootModel)" | Add-Content $OutFile -Encoding utf8
        
                            "VC$($vcNo)C$($ClusterNo)_$($FixCluster) $($RelationShip) VC$($vcNo)C$($ClusterNo)M$($ModelNo)_$($FixModel)" | Add-Content $OutFile -Encoding utf8
                                    
                            #region Group PhysicalLocation
                            $InputObject | Where-Object vCenterServer -match $vCenter | Where-Object Cluster -match $RootCluster | Where-Object Model -match $RootModel | Group-Object PhysicalLocation | Select-Object -ExpandProperty Name | ForEach-Object {

                                Write-Verbose "PhysicalLocation $($_)"
                                $PhysicalLocation = $_
                                $ObjectCount = $InputObject | Where-Object vCenterServer -match $vCenter | Where-Object Cluster -match $RootCluster | Where-Object Model -match $RootModel | Where-Object PhysicalLocation -match $PhysicalLocation | Select-Object -ExpandProperty HostName

                                "VC$($vcNo)C$($ClusterNo)M$($ModelNo)_$($FixModel) : - $($PhysicalLocation), $($ObjectCount.count) ESXi Hosts" | Add-Content $OutFile -Encoding utf8

                                "VC$($vcNo)C$($ClusterNo)M$($ModelNo)_$($FixModel) $($RelationShip) VC$($vcNo)C$($ClusterNo)M$($ModelNo)_$($PhysicalLocation)" | Add-Content $OutFile -Encoding utf8

                                #region Group HostName
                                $InputObject | Where-Object vCenterServer -match $vCenter | Where-Object Cluster -match $RootCluster | Where-Object Model -match $RootModel | Where-Object PhysicalLocation -match $PhysicalLocation | Group-Object HostName | Select-Object -ExpandProperty Name | ForEach-Object {
                                    
                                    $HostObject = $InputObject | Where-Object HostName -match $($_)
                                    $ESXiHost   = $($HostObject.HostName).Split('.')[0]

                                    if($HostObject.ConnectionState -eq 'Connected'){
                                        $prefix = '+'
                                    }elseif($HostObject.ConnectionState -match 'New'){
                                        $prefix = 'o'
                                    }else{
                                        $prefix = '-'
                                    }

                                    "VC$($vcNo)C$($ClusterNo)M$($ModelNo)_$($PhysicalLocation) : $($prefix) $($ESXiHost), ESXi $($HostObject.Version), $($RootModel)" | Add-Content $OutFile -Encoding utf8
                                }
                                #endregion HostName
                                
                            }
                            #endregion PhysicalLocation
                        
                            $ModelNo = 0
                        }
                        #endregion Group Model
                    }
                }

                $ClusterNo = 0
                #endregion Group Cluster

                "`````````n" | Add-Content $OutFile -Encoding utf8
                "[Top](#)`n" | Add-Content $OutFile -Encoding utf8
            }
        }
        #endregion Group vCenter

        "---`n" | Add-Content $OutFile -Encoding utf8
        "I $([char]9829) PS > Diagram created with PowerShell and Mermaid at $((Get-Date).ToString())`n" | Add-Content $OutFile -Encoding utf8
        "---" | Add-Content $OutFile -Encoding utf8
        
        Start-Process $($OutFile)

    }catch{
        Write-Warning $('ScriptName:', $($_.InvocationInfo.ScriptName), 'LineNumber:', $($_.InvocationInfo.ScriptLineNumber), 'Message:', $($_.Exception.Message) -Join ' ')
        $error.Clear()
    }

}

end{
    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', $function -Join ' ')
    $TimeSpan  = New-TimeSpan -Start $StartTime -End (Get-Date)
    $Formatted = $TimeSpan | ForEach-Object {
        '{1:0}h {2:0}m {3:0}s {4:000}ms' -f $_.Days, $_.Hours, $_.Minutes, $_.Seconds, $_.Milliseconds
    }
    Write-Verbose $('Finished in:', $Formatted -Join ' ')

    return $($OutFile)
}