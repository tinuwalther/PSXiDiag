<#
.SYNOPSIS
    New-PshtmlVCSADiagram.ps1

.DESCRIPTION
    New-PshtmlVCSADiagram - Create a Mermaid Class Diagram.

.PARAMETER InputObject
    Specify a valid InputObject.

.PARAMETER InputObject
    Specify a valid InputObject.
    
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
    
.PARAMETER Title
    Specify a valid Title for the Website.
    
.EXAMPLE
    .\New-PshtmlVCSADiagram.ps1 -InputObject (Import-Csv -Path ..\data\inventory.csv -Delimiter ';') -Title 'PSHTML ESXiHost Inventory'

    Import-Csv with the Semicolon-Delimiter and create the Mermaid-Diagram with the content of the CSV and the Title 'PSHTML ESXiHost Inventory' as Html.

.EXAMPLE
    $Parameters = @{
        Column      = @{
            Field01 = 'vCenterServer'
            Field02 = 'Cluster'
            Field03 = 'Model'
            Field04 = 'PhysicalLocation'
            Field05 = 'HostName'
            Field06 = 'ConnectionState'
        }
        InputObject = Import-Csv -Path ..\data\inventory.csv -Delimiter ';'
        Title       = 'PSHTML ESXiHost Inventory'
    }
    .\New-AdvancedVCSADiagram.ps1 @Parameters 

    Import from a JSON-File and create the Mermaid-Diagram with the content of the CSV and the Title 'PSHTML ESXiHost Inventory' as Html.

#>

#Requires -Modules PSHTML

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
    
    $vcNo = 0; $ClusterNo = 0; $ModelNo = 0
    $Page = $($MyInvocation.MyCommand.Name) -replace '.ps1'

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Process ]', $function -Join ' ')
    $OutFile = (Join-Path -Path $($PSScriptRoot).Replace('bin','output') -ChildPath "$($Title).html") -replace '\s', '-'
    Write-Verbose $OutFile
    
    # Specify assets-path
    $AssetsPath = '../assets' #$AssetsPath = $($PSScriptRoot).Replace('bin','assets')
    Write-Verbose $AssetsPath

    $ContinerStyleFluid  = 'container-fluid'

    #region header
    $HeaderTitle        = $Page
    $HeaderCaption      = $($Title)
    #endregion

    #region body
    $BodyDescription    = "PsMmaDiagram builds Mermaid Diagrams with PSHTML and PowerShell as HTML-Files from an object of VMware ESXiHosts"
    #endregion
    
    #region footer
    $FooterSummary      = "Report saved as $($OutFile)"
    #endregion

    #region scriptblock
    $navbar = {

        #region <!-- nav -->
        nav -class "navbar navbar-expand-sm bg-dark navbar-dark sticky-top" -content {
            a -class "navbar-brand" -href "#" -content {'HOME'}

            # <!-- Toggler/collapsibe Button -->
            button -class "navbar-toggler" -Attributes @{
                "type"="button"
                "data-toggle"="collapse"
                "data-target"="#collapsibleNavbar"
            } -content {
                span -class "navbar-toggler-icon"
            }

            #region <!-- Navbar links -->
            div -class "collapse navbar-collapse" -id "collapsibleNavbar" -Content {
                ul -class "navbar-nav" -content {
                    #FixedLinks
                    # li -class "nav-item" -content {
                    #     a -class "nav-link" -href "https://pshtml.readthedocs.io/" -Target _blank -content { "PSHTML" }
                    # }
                    #DynamicLinks
                    $InputObject | Group-Object $Column.Field01 | Select-Object -ExpandProperty Name | ForEach-Object {
                        $vCenter = $($_).Split('.')[0]
                        if(-not([String]::IsNullOrEmpty($vCenter))){
                            li -class "nav-item" -content {
                                a -class "nav-link" -href "#$($vCenter)" -content { $($vCenter) }
                            }
                        }
                    }
                }
            }
            #endregion Navbar links
        }
        #endregion nav

    }

    $article = {

        #region <!-- vCenter -->
        $InputObject | Group-Object $Column.Field01 | Select-Object -ExpandProperty Name | ForEach-Object {

            #region <!-- Content -->
            div -id "Content" -Class "$($ContinerStyleFluid)" -Style "background-color:#034f84" {

                #region  <!-- article -->
                article -id "mermaid" -Content {

                    $vcNo ++
                    $vCenter = $($_).Split('.')[0]

                    if(-not([String]::IsNullOrEmpty($vCenter))){

                        h3 -Id $($vCenter) -Content {
                            a -href "https://$($_)/ui/" -Target _blank -content { "vCenter $($vCenter)" }
                        } -Style "color:#198754; text-align: center"
                        hr

                        #region mermaid
                        div -Class "mermaid" -Style "text-align: center" {
                            
                            "classDiagram`n"

                            #region Group Cluster
                            $InputObject | Where-Object $Column.Field01 -match $_ | Group-Object $Column.Field02 | Select-Object -ExpandProperty Name | ForEach-Object {
                                
                                if(-not([String]::IsNullOrEmpty($_))){

                                    $ClusterNo ++
                                    $RootCluster = $_
                                    $FixCluster  = $RootCluster -replace '-'

                                    # Print out vCenter --> Cluster
                                    "VC$($vcNo)_$($vCenter) $($RelationShip) VC$($vcNo)C$($ClusterNo)_$($FixCluster)`n"
                                    "VC$($vcNo)_$($vCenter) : + $($RootCluster)`n"

                                    #region Group Model
                                    $InputObject | Where-Object $Column.Field01 -match $vCenter | Where-Object $Column.Field02 -match $RootCluster | Group-Object $Column.Field03 | Select-Object -ExpandProperty Name | ForEach-Object {
                                        
                                        Write-Verbose "Model: $($_)"

                                        $ModelNo ++
                                        $RootModel = $_
                                        $FixModel  = $RootModel -replace '-'

                                        "VC$($vcNo)C$($ClusterNo)_$($FixCluster) : + $($RootModel)`n"
                    
                                        "VC$($vcNo)C$($ClusterNo)_$($FixCluster) $($RelationShip) VC$($vcNo)C$($ClusterNo)_$($FixModel)`n"
                                                
                                        #region Group PhysicalLocation
                                        $InputObject | Where-Object $Column.Field01 -match $vCenter | Where-Object $Column.Field02 -match $RootCluster | Where-Object $Column.Field03 -match $RootModel | Group-Object $Column.Field04 | Select-Object -ExpandProperty Name | ForEach-Object {

                                            Write-Verbose "PhysicalLocation $($_)"
                                            $PhysicalLocation = $_
                                            $ObjectCount = $InputObject | Where-Object $Column.Field01 -match $vCenter | Where-Object $Column.Field02 -match $RootCluster | Where-Object $Column.Field03 -match $RootModel | Where-Object $Column.Field04 -match $PhysicalLocation | Select-Object -ExpandProperty $Column.Field05
                                            
                                            "VC$($vcNo)C$($ClusterNo)_$($FixModel) : - $($PhysicalLocation), $($ObjectCount.count) ESXi Hosts`n"

                                            "VC$($vcNo)C$($ClusterNo)_$($FixModel) $($RelationShip) VC$($vcNo)C$($ClusterNo)_$($PhysicalLocation)`n"

                                            #region Group HostName
                                            $InputObject | Where-Object $Column.Field01 -match $vCenter | Where-Object $Column.Field02 -match $RootCluster | Where-Object $Column.Field03 -match $RootModel | Where-Object $Column.Field04 -match $PhysicalLocation | Group-Object $Column.Field05 | Select-Object -ExpandProperty Name | ForEach-Object {
                                                
                                                $HostObject = $InputObject | Where-Object $Column.Field05 -match $($_)
                                                $ESXiHost   = $($HostObject.$($Column.Field05)).Split('.')[0]

                                                if($HostObject.$($Column.Field06) -eq 'Connected'){
                                                    $prefix = '+'
                                                }elseif($HostObject.$($Column.Field06) -match 'New'){
                                                    $prefix = 'o'
                                                }else{
                                                    $prefix = '-'
                                                }

                                                "VC$($vcNo)C$($ClusterNo)_$($PhysicalLocation) : $($prefix) $($ESXiHost), ESXi $($HostObject.Version), $($RootModel)`n"
                                            }
                                            #endregion HostName
                                            
                                        }
                                        #endregion PhysicalLocation
                                    
                                        $ModelNo = 0
                                    }
                                    #endregion Group Model

                                }else{
                                    Write-Verbose "Empty Cluster"
                                }

                            }
                            #endregion Group Cluster

                            $ClusterNo = 0
                        }
                        #endregion mermaid

                    }else{
                        Write-Verbose "Emptry vCenter"
                    }

                }
                #endregion article

            }
            #endregion content
        } 
        #endregion vCenter

    }
    #endregion scriptblock

    #region HTML
    $HTML = html {

        #region head
        head {
            meta -charset 'UTF-8'
            meta -name 'author' -content "Martin Walther"  
            meta -name "keywords" -content_tag "PSHTML, PowerShell, Mermaid Diagram"
            meta -name "description" -content_tag "PsMmaDiagram builds Mermaid Diagrams as HTML-Files with PSHTML from native PowerShell-Scripts"

            # CSS
            Link -rel stylesheet -href $(Join-Path -Path $AssetsPath -ChildPath 'BootStrap/bootstrap.min.css')
            Link -rel stylesheet -href $(Join-Path -Path $AssetsPath -ChildPath 'style/style.css')

            # Scripts
            Script -src $(Join-Path -Path $AssetsPath -ChildPath 'BootStrap/bootstrap.js')
            Script -src $(Join-Path -Path $AssetsPath -ChildPath 'Jquery/jquery.min.js')
            Script -src $(Join-Path -Path $AssetsPath -ChildPath 'mermaid/mermaid.min.js')
            Script {mermaid.initialize({startOnLoad:true})}
    
            title $HeaderTitle
        } 
        #endregion header

        #region body
        body {

            #region <!-- header -->
            header  {
                div -id "j1" -class 'jumbotron text-center' -Style "padding:15; background-color:#033b63" -content {
                    p { h1 $HeaderTitle }
                    p { h2 $HeaderCaption }  
                    p { $BodyDescription }  
                }
            }
            #endregion header

            #region <!-- section -->
            section -id "section" -Content {  

                Invoke-Command -ScriptBlock $navbar

                #region <!-- column -->
                div -Class "$($ContinerStyleFluid)" -Style "background-color:#034f84" {
                
                    Invoke-Command -ScriptBlock $article

                }
                #endregion column

            }
            #endregion section
            
        }
        #endregion body

        #region footer
        div -Class $ContinerStyleFluid -Style "background-color:#343a40" {
            Footer {

                div -Class $ContinerStyleFluid {
                    div -Class "row align-items-center" {
                        div -Class "col-md" {
                            p {
                                a -href "#" -content { "I $([char]9829) PS >" }
                            }
                        }
                        div -Class "col-md" {
                            p {$FooterSummary}
                        }
                        div -Class "col-md" {
                            p {$((Get-Date).ToString())}
                        }
                    }
                }
        
            }
        }
        #endregion footer

    }
    $Html | Set-Content $OutFile -Encoding utf8
    #endregion html

    if($CurrentOS -eq [OSType]::Windows){
        Start-Process $($OutFile)
    }else{
        Start-Process "file://$($OutFile)"
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
