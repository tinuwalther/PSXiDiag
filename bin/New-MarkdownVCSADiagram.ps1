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
    
    
.PARAMETER Column
    Specify the column-header of the Object, default is:
    $Column = @{
        Field01 = 'vCenterServer'
        Field02 = 'Cluster'
        Field03 = 'Model'
        Field04 = 'PhysicalLocation'
        Field05 = 'HostName'
        Field06 = 'ConnectionState'
    }
   
.EXAMPLE
    .\New-MarkdownVCSADiagram.ps1 -InputObject (Import-Csv -Path ..\data\inventory.csv -Delimiter ';') -Title 'Markdown ESXiHost Inventory'

    Import-Csv with the default Delimiter and create the Mermaid-Diagram with the content of the CSV and the Title 'Markdown ESXiHost Inventory' as Markdown.

.EXAMPLE
    .\New-MarkdownVCSADiagram.ps1 -InputObject (Get-Content ..\data\Inventory.json | ConvertFrom-Json) -Title 'Markdown ESXiHost Inventory'

    Import from a JSON-File and create the Mermaid-Diagram with the content of the CSV and the Title 'HTML ESXiHost Inventory' as Markdown.

#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [Object]$InputObject,

    [Parameter(Mandatory=$false)]
    [PSCustomObject]$Column = @{
        Field01 = 'vCenterServer'
        Field02 = 'Cluster'
        Field03 = 'Model'
        Field04 = 'PhysicalLocation'
        Field05 = 'HostName'
        Field06 = 'ConnectionState'
    },

    [Parameter(Mandatory=$false)]
    [String]$RelationShip = '--',

    [Parameter(Mandatory=$true)]
    [String]$Title
)


begin{    
    $StartTime = Get-Date
    $function = $($MyInvocation.MyCommand.Name)
    foreach($item in $PSBoundParameters.keys){
        $params = "$($params) -$($item) $($PSBoundParameters[$item])"
    }
    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', "$($function)$($params)" -Join ' ')

    enum OSType {
        Linux
        Mac
        Windows
    }

    if($PSVersionTable.PSVersion.Major -lt 6){
        $CurrentOS = [OSType]::Windows
    }else{
        if($IsMacOS)  {$CurrentOS = [OSType]::Mac}
        if($IsLinux)  {$CurrentOS = [OSType]::Linux}
        if($IsWindows){$CurrentOS = [OSType]::Windows}
    }
}

process{

    #Fields = HostName;Version;Manufacturer;Model;vCenterServer;Cluster;PhysicalLocation;ConnectionState

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Process ]', $function -Join ' ')

    $vcNo = 0; $ClusterNo = 0; $ModelNo = 0

    #$OutFile = (Join-Path -Path $($PSScriptRoot).Replace('bin','output') -ChildPath "$($Title).md") -replace '\s', '-'

    # for Pode Server
    $PodeViews = Join-Path -Path $($PSScriptRoot).Replace('bin','pode') -ChildPath 'views'
    $PodeDir   = Join-Path -Path $PodeViews -ChildPath 'md'
    $PodeFile  = (("$($Title).md") -replace '\s', '-')
    $OutFile   = Join-Path -Path $($PodeDir) -ChildPath $($PodeFile)
    Write-Verbose "OutFile: $($OutFile)"

    try{
        $MarkdownOut = @()

        #region Markdown Header
        $MarkdownOut += "# $($Title)`n"
        #endregion

        #region vCenterServer Nav Links
        $GroupVC = $InputObject | Group-Object $Column.Field01 | Select-Object -ExpandProperty Name
        $MarkdownOut += $GroupVC | ForEach-Object {
            $vCenter = $($_).Split('.')[0]
            if(-not([String]::IsNullOrEmpty($vCenter))){
                " - [vCenter $($vCenter)](`#vcenter-$(($vCenter).ToLower()))" 
            }
        }
        #endregion
        
        $MarkdownOut += "`n"
        $MarkdownOut += '<html><script src="/assets/mermaid/mermaid.min.js"></script></html>'
        $MarkdownOut += "`n"

        #region Group vCenter
        $MarkdownOut += $GroupVC | ForEach-Object {

            $vcNo ++
            $vCenter = $($_).Split('.')[0]
            if(-not([String]::IsNullOrEmpty($vCenter))){
                Write-Verbose "vCenter: $($_)"

                #region section header
                "---`n" 
                "## [vCenter $($vCenter)](https://$($_)/ui)`n" 
                "---`n" 
        
                #region ESXiHosts
                $InputObject | Where-Object $Column.Field01 -match $_ | Group-Object vCenterServer | ForEach-Object {
                    $CountOfVersion = $_.Group.Version | Group-Object | ForEach-Object {
                        "$($_.Name) = $($_.Count)"
                    }
                    "Total ESXiHosts in $($vCenter): $($_.Count) (ESXi Versions: $($CountOfVersion -join ', '))`n" 
                }
                #endregion

                "````````mermaid" 
                "classDiagram"    
                #endregion

                #region Group Cluster
                $InputObject | Where-Object $Column.Field01 -match $_ | Group-Object $Column.Field02 | Select-Object -ExpandProperty Name | ForEach-Object {
                    if(-not([String]::IsNullOrEmpty($_))){

                        Write-Verbose "Cluster: $($_)"

                        $ClusterNo ++
                        $RootCluster = $_
                        # Markdown don't like some characters
                        $FixCluster  = $RootCluster -replace '-' -replace '\(' -replace '\)'

                        # One vCenter has relations to clusters
                        "VC$($vcNo)_$($vCenter) $($RelationShip) VC$($vcNo)C$($ClusterNo)_$($FixCluster)" 
                        "VC$($vcNo)_$($vCenter) : + $($RootCluster)" 
        
                        #region Group Model
                        $InputObject | Where-Object $Column.Field01 -match $vCenter | Where-Object $Column.Field02 -match $RootCluster | Group-Object Model | Select-Object -ExpandProperty Name | ForEach-Object {
                            
                            Write-Verbose "Model: $($_)"

                            $ModelNo ++
                            $RootModel = $_
                            # Markdown don't like some characters
                            $FixModel  = $RootModel -replace '-' -replace '\(' -replace '\)'

                            # A cluster contains hardware model(s)
                            "VC$($vcNo)C$($ClusterNo)_$($FixCluster) : + $($RootModel)" 
        
                            "VC$($vcNo)C$($ClusterNo)_$($FixCluster) $($RelationShip) VC$($vcNo)C$($ClusterNo)_$($FixModel)" 
                                    
                            #region Group PhysicalLocation
                            $InputObject | Where-Object $Column.Field01 -match $vCenter | Where-Object $Column.Field02 -match $RootCluster | Where-Object Model -match $RootModel | Group-Object $Column.Field04 | Select-Object -ExpandProperty Name | ForEach-Object {

                                Write-Verbose "PhysicalLocation $($_)"
                                $PhysicalLocation = $_
                                $ObjectCount = $InputObject | Where-Object $Column.Field01 -match $vCenter | Where-Object $Column.Field02 -match $RootCluster | Where-Object $Column.Field03 -match $RootModel | Where-Object $Column.Field04 -match $PhysicalLocation | Select-Object -ExpandProperty $Column.Field05

                                # A hardware model can be in one or more physical locations
                                "VC$($vcNo)C$($ClusterNo)_$($FixModel) : - $($PhysicalLocation), $($ObjectCount.count) ESXi Hosts" 

                                "VC$($vcNo)C$($ClusterNo)_$($FixModel) $($RelationShip) VC$($vcNo)C$($ClusterNo)_$($PhysicalLocation)" 

                                #region Group HostName
                                $InputObject | Where-Object $Column.Field01 -match $vCenter | Where-Object $Column.Field02 -match $RootCluster | Where-Object $Column.Field03 -match $RootModel | Where-Object $Column.Field04 -match $PhysicalLocation | Group-Object $Column.Field05 | Select-Object -ExpandProperty Name | ForEach-Object {
                                    
                                    $HostObject = $InputObject | Where-Object $Column.Field05 -match $($_)
                                    $ESXiHost   = $($HostObject.$($Column.Field05)).Split('.')[0]

                                    # Visualize the status of the ESXiHost
                                    if($HostObject.$($Column.Field06) -eq 'Connected'){
                                        $prefix = '+'
                                    }elseif($HostObject.$($Column.Field06) -match 'New'){
                                        $prefix = 'o'
                                    }else{
                                        $prefix = '-'
                                    }

                                    # Each physical location contains ESXiHosts
                                    "VC$($vcNo)C$($ClusterNo)_$($PhysicalLocation) : $($prefix) $($ESXiHost), ESXi $($HostObject.Version), $($RootModel)" 
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

                "`````````n" 

                "[Top](#)`n" 
            }
        }
        #endregion Group vCenter

        #region ESXiHosts
        $CountOfVersion = $InputObject | Group-Object Version | ForEach-Object {
            "$($_.Name) = $($_.Count)"
        }
        $MarkdownOut += "Total ESXiHosts: $(($InputObject.$($Column.Field01)).count) (ESXi Versions: $($CountOfVersion -join ', '))`n" 
        #endregion

        #region footer
        $MarkdownOut += "---`n" 
        $MarkdownOut += "I $([char]9829) PS > Diagram created with PowerShell and Mermaid at $((Get-Date).ToString())`n" 
        $MarkdownOut += "---" 
        #endregion
        
        $MarkdownOut | Set-Content $OutFile -Encoding utf8

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