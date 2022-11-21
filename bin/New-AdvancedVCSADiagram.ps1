#Requires -Modules PSHTML
<#
.SYNOPSIS
    New-AdvancedVCSADiagram.ps1

.DESCRIPTION
    New-AdvancedVCSADiagram - Create a Mermaid Class Diagram.

.PARAMETER InputObject
    Specify a valid InputObject.
    
.PARAMETER RelationShip
    Specify a valid RelationShip.
    
.PARAMETER Title
    Specify a valid Title for the Website.
    
.EXAMPLE
    .\New-AdvancedVCSADiagram.ps1 -InputObject (Import-Csv -Path ..\data\inventory.csv -Delimiter ';') -Title 'ESXiHost Inventory'

    Import-Csv with the Semicolon-Delimiter and create the Mermaid-Diagram with the content of the CSV and the Title 'ESXiHost Inventory' as Html.

.EXAMPLE
    .\New-AdvancedVCSADiagram.ps1 -InputObject (Get-Content ..\data\Inventory.json | ConvertFrom-Json) -Title 'ESXiHost Inventory' -Title 'ESXiHost Inventory'

    Import from a JSON-File and create the Mermaid-Diagram with the content of the CSV and the Title 'ESXiHost Inventory' as Html.

#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [Object]$InputObject,

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
}

process{
    $vcNo = 0; $ClusterNo = 0; $ModelNo = 0
    $Page = $($MyInvocation.MyCommand.Name) -replace '.ps1'

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Process ]', $function -Join ' ')
    $OutFile = Join-Path -Path $($PSScriptRoot).Trim('bin') -ChildPath $($($MyInvocation.MyCommand.Name) -replace '.ps1', '.html')
    
    Write-Verbose $OutFile
    $ContinerStyle       = 'container'
    $ContinerStyleFluid  = 'container-fluid'

    #region header
    $HeaderTitle        = $Page
    $HeaderCaption      = $($Title)
    #endregion

    #region body
    $BodyDescription    = "Create an advanced Class Diagram from an object of VMware ESXiHost Inventory"
    #endregion
    
    #region footer
    $FooterSummary      = "Diagram created with PSHTML>, PowerShell and Mermaid"
    #endregion

    #region HTML
    $HTML = html {

        #region head
        head {
            meta -charset 'UTF-8'
            meta -name 'author' -content "Martin Walther"  

            Link -href "assets/BootStrap/bootstrap.min.css" -rel stylesheet
            Link -href "style/style.css" -rel stylesheet

            Script -src "assets/Jquery/jquery.min.js"

            Script -src "assets/Chartjs/Chart.bundle.min.js"

            script -src "assets/mermaid/mermaid.min.js"
            
            script {mermaid.initialize({startOnLoad:true})}

            Script -src "assets/BootStrap/bootstrap.js"
            Script -src "assets/BootStrap/bootstrap.min.js"
    
            title $HeaderTitle
        } 
        #endregion header

        #region body
        body {

            #region <!-- header -->
            header {
                div -id "j1" -class 'jumbotron text-center' -content {
                    p { h1 $HeaderTitle }
                    p { h2 $HeaderCaption }  
                    p { $BodyDescription }  
                } -Style "padding:15; background-color:#033b63"
            } -Style "background-color:#dee2e6"
            #endregion header

            #region <!-- section -->
            section -id "section" -Content {  

                #region <!-- nav -->
                nav -class "navbar navbar-expand-sm bg-dark navbar-dark sticky-top" -content {
                    a -class "navbar-brand" -href "#" -content {'PsMermaidDiagram'}

                    # <!-- Toggler/collapsibe Button -->
                    button -class "navbar-toggler" -Attributes @{
                        "type"="button"
                        "data-toggle"="collapse"
                        "data-target"="#collapsibleNavbar"
                    } -content {
                        span -class "navbar-toggler-icon"
                    }

                    # <!-- Navbar links -->
                    div -class "collapse navbar-collapse" -id "collapsibleNavbar" -Content {
                        ul -class "navbar-nav" -content {
                            #FixedLinks
                            li -class "nav-item" -content {
                                a -class "nav-link" -href "https://pshtml.readthedocs.io/" -Target _blank -content { "PSHTML" }
                            }
                            #DynamicLinks
                            $InputObject | Group-Object vCenterServer | Select-Object -ExpandProperty Name | ForEach-Object {
                                $vCenter = $($_).Split('.')[0]
                                if(-not([String]::IsNullOrEmpty($vCenter))){
                                    li -class "nav-item" -content {
                                        a -class "nav-link" -href "#$($vCenter)" -content { $($vCenter) }
                                    }
                                }
                            }
                        }
                    }
                }
                #endregion nav

                #region <!-- column -->
                div -Class "$($ContinerStyleFluid)" {
                    
                    #region <!-- vCenter -->
                    $InputObject | Group-Object vCenterServer | Select-Object -ExpandProperty Name | ForEach-Object {

                        #region <!-- Content -->
                        div -id "Content" -Class "$($ContinerStyleFluid)" {

                            #region  <!-- article -->
                            article -id "mermaid" -Content {

                                $vcNo ++
                                $vCenter = $($_).Split('.')[0]

                                if(-not([String]::IsNullOrEmpty($vCenter))){

                                    h3 -Id $($vCenter) -Content {
                                        "vCenter $($vCenter)"
                                    } -Style "color:#198754; text-align: center"
                                    hr
                                    div -Class "mermaid" {
                                        
                                        "classDiagram`n"

                                        #region Group Cluster
                                        $InputObject | Where-Object vCenterServer -match $_ | Group-Object Cluster | Select-Object -ExpandProperty Name | ForEach-Object {
                                            
                                            if(-not([String]::IsNullOrEmpty($_))){

                                                $ClusterNo ++
                                                $RootCluster = $_
                                                $FixCluster  = $RootCluster -replace '-'

                                                "VC$($vcNo)_$($vCenter) $($RelationShip) VC$($vcNo)C$($ClusterNo)_$($FixCluster)`n"
                                                "VC$($vcNo)_$($vCenter) : + $($RootCluster)`n"

                                            }else{
                                                Write-Verbose "Empty Cluster"
                                            }

                                        }
                                        $ClusterNo = 0
                                        #endregion Group Cluster
                                    } -Style "text-align: center"
                                    p {
                                        a -href "#" -content { "Top" }
                                    } -Style "text-align: center"
                                    #endregion mermaid

                                }else{
                                    Write-Verbose "Emptry vCenter"
                                }
                                #endregion
                            }
                            #endregion article

                        } -Style "background-color:#034f84"
                        #endregion content
                    } 
                    #endregion vCenter

                } -Style "background-color:#034f84"
                #endregion column
            }
            #endregion section
        }
        #endregion body

        #region footer
        div -Class $ContinerStyleFluid {
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
        } -Style "background-color:#343a40"
        #endregion footer

    }
    $Html | Set-Content $OutFile -Encoding utf8
    #endregion html
}

end{
    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', $function -Join ' ')
    $TimeSpan  = New-TimeSpan -Start $StartTime -End (Get-Date)
    $Formatted = $TimeSpan | ForEach-Object {
        '{1:0}h {2:0}m {3:0}s {4:000}ms' -f $_.Days, $_.Hours, $_.Minutes, $_.Seconds, $_.Milliseconds
    }
    Write-Verbose $('Finished in:', $Formatted -Join ' ')

    Start-Process $($OutFile)
    return $($OutFile)
}
