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
    
.PARAMETER Markdown
    Switch, if omitted the Output is saved as Html-File else as Markdown-File.
    
.EXAMPLE
    .\New-AdvancedVCSADiagram.ps1 -InputObject (Import-Csv -Path ..\data\inventory.csv -Delimiter ';') -Title 'ESXiHost Inventory'

    Import-Csv with the default Delimiter and create the Mermaid-Diagram with the content of the CSV and the Title 'ESXiHost Inventory' as Markdown.

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
    [String]$Title,

    [Parameter(Mandatory=$false)]
    [Switch]$Markdown
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

    if($Markdown){
        $OutFile = Join-Path -Path $($PSScriptRoot).Trim('bin') -ChildPath $($($MyInvocation.MyCommand.Name) -replace '.ps1', '.md')
        Write-Verbose $OutFile
    }else{
        $OutFile = Join-Path -Path $($PSScriptRoot).Trim('bin') -ChildPath $($($MyInvocation.MyCommand.Name) -replace '.ps1', '.html')
        Write-Verbose $OutFile
    }

}

process{
    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Process ]', $function -Join ' ')

    $ContinerStyle       = 'container-fluid' #'container'

    #region header
    $HeaderTitle        = $Page
    $HeaderCaption      = $($Title)
    #endregion

    #region body
    $BodyDescription    = "Create an advanced Class Diagram from an object of VMware ESXiHost Inventory."
    #endregion
    
    #region footer
    $FooterSummary      = "Diagram created with PowerShell and Mermaid"
    #endregion

    #region HTML
    $HTML = html {

        #region header                       
        head {
            meta -charset 'UTF-8'
            meta -name 'author' -content "Martin Walther"  

            Link -href "assets/BootStrap/bootstrap.min.css" -rel stylesheet
            Link -href "style/style.css" -rel stylesheet

            Script -src "assets/Jquery/jquery.min.js"

            Script -src "assets/Chartjs/Chart.bundle.min.js"

            Script -src "assets/BootStrap/bootstrap.js"
            Script -src "assets/BootStrap/bootstrap.min.js"
    
            title $HeaderTitle
            #Write-PSHTMLAsset -Name Jquery
            #Write-PSHTMLAsset -Name BootStrap
            #Write-PSHTMLAsset -Name Chartjs
        } 
        #endregion header

        #region body
        body {

            # <!-- Do not change the nav -->
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
                        li -class "nav-item" -content {
                            a -class "nav-link" -href "https://getbootstrap.com/" -Target _blank -content { "Bootstrap" }
                        }
                        li -class "nav-item" -content {
                            a -class "nav-link" -href "https://www.w3schools.com/" -Target _blank -content { "w3schools" }
                        }
                    }
                }
            }

            # <!-- Section Content -->
            article -id "article" -Content {    

                div -id "j1" -class 'jumbotron text-center' -content {
                    p { h1 $HeaderTitle }  
                    p { h2 $HeaderCaption }  
                }

                div -Class $ContinerStyle {
                    article -id "Test" -Content {
                        div -Class "col-sm" {
                            p { $BodyDescription }  
                        }
                    }
                }
            }

        }
        #endregion body

        #region footer
        div -Class "container-fluid" {
            Footer {

                div -Class "container" {
                    div -Class "row align-items-center" {
                        div -Class "col-md" {
                            p {"I $([char]9829) PS >"}
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
    #endregion html

    # try{

    #     #region HTML/Markdown Header
    #     if($Markdown){
    #         "# $($Header) - $($Title)`n" | Set-Content $OutFile -Encoding utf8 -Force
    #     }else{
    #     }
    #     #endregion

    #     #region vCenterServer Nav Links
    #     if(-not($Markdown)){'<nav>' | Add-Content $OutFile -Encoding utf8}
    #     $GroupVC = $InputObject | Group-Object vCenterServer | Select-Object -ExpandProperty Name
    #     $GroupVC | ForEach-Object {
    #         $vCenter = $($_).Split('.')[0]
    #         if(-not([String]::IsNullOrEmpty($vCenter))){
    #             if($Markdown){
    #                 " - [vCenter $($vCenter)](`#vcenter-$(($vCenter).ToLower()))" | Add-Content $OutFile -Encoding utf8
    #             }else{
    #                 "<button class='button-small'><a href='#$($vCenter)'><b>$vCenter</b></a></button>" | Add-Content $OutFile -Encoding utf8 -Force
    #             }
    #         }
    #     }
    #     if(-not($Markdown)){'</nav>' | Add-Content $OutFile -Encoding utf8}
    #     #endregion

    #     #region Group vCenter
    #     $GroupVC | ForEach-Object {

    #         $vcNo ++
    #         $vCenter = $($_).Split('.')[0]
    #         if(-not([String]::IsNullOrEmpty($vCenter))){
    #             Write-Verbose "vCenter: $($_)"

    #             #region section header
    #             if($Markdown){
    #                 "---`n" | Add-Content $OutFile -Encoding utf8
    #                 "## [vCenter $($vCenter)](https://$($_)/ui)`n" | Add-Content $OutFile -Encoding utf8
    #                 "---`n" | Add-Content $OutFile -Encoding utf8
            
    #                 "````````mermaid" | Add-Content $OutFile -Encoding utf8
    #                 "classDiagram"    | Add-Content $OutFile -Encoding utf8
    #             }else{
    #                 "<hr><h3 id='$($vCenter)'><a href='https://$($_)/ui' target='_blank'>vCenter $($vCenter)</a></h3><hr>" | Add-Content $OutFile -Encoding utf8
    #                 '<div class="mermaid">' | Add-Content $OutFile -Encoding utf8
    #                 'classDiagram' | Add-Content $OutFile -Encoding utf8
    #             }
    #             #endregion

    #             #region Group Cluster
    #             $InputObject | Where-Object vCenterServer -match $_ | Group-Object Cluster | Select-Object -ExpandProperty Name | ForEach-Object {
    #                 if(-not([String]::IsNullOrEmpty($_))){

    #                     Write-Verbose "Cluster: $($_)"

    #                     $ClusterNo ++
    #                     $RootCluster = $_
    #                     $FixCluster  = $RootCluster -replace '-'

    #                     "VC$($vcNo)_$($vCenter) $($RelationShip) VC$($vcNo)C$($ClusterNo)_$($FixCluster)" | Add-Content $OutFile -Encoding utf8
    #                     "VC$($vcNo)_$($vCenter) : + $($RootCluster)" | Add-Content $OutFile -Encoding utf8
        
    #                     #region Group Model
    #                     $InputObject | Where-Object vCenterServer -match $vCenter | Where-Object Cluster -match $RootCluster | Group-Object Model | Select-Object -ExpandProperty Name | ForEach-Object {
                            
    #                         Write-Verbose "Model: $($_)"

    #                         $ModelNo ++
    #                         $RootModel = $_
    #                         $FixModel  = $RootModel -replace '-'

    #                         "VC$($vcNo)C$($ClusterNo)_$($FixCluster) : + $($RootModel)" | Add-Content $OutFile -Encoding utf8
    #                         #"VC$($vcNo)C$($ClusterNo)_$($Cluster) : Get-Model()" | Add-Content $OutFile -Encoding utf8
        
    #                         "VC$($vcNo)C$($ClusterNo)_$($FixCluster) $($RelationShip) VC$($vcNo)C$($ClusterNo)M$($ModelNo)_$($FixModel)" | Add-Content $OutFile -Encoding utf8
    #                         #"VC$($vcNo)C$($ClusterNo)_$($Model) : Get-Datacenter()" | Add-Content $OutFile -Encoding utf8
                                    
    #                         #region Group Datacenter
    #                         $InputObject | Where-Object vCenterServer -match $vCenter | Where-Object Cluster -match $RootCluster | Where-Object Model -match $RootModel | Group-Object Datacenter | Select-Object -ExpandProperty Name | ForEach-Object {

    #                             Write-Verbose "Datacenter $($_)"
    #                             $Datacenter = $_
                                
    #                             "VC$($vcNo)C$($ClusterNo)M$($ModelNo)_$($FixModel) $($RelationShip) VC$($vcNo)C$($ClusterNo)M$($ModelNo)_$($Datacenter)" | Add-Content $OutFile -Encoding utf8

    #                             #region Group HostName
    #                             $InputObject | Where-Object vCenterServer -match $vCenter | Where-Object Model -match $RootModel | Where-Object Datacenter -match $Datacenter | Group-Object HostName | Select-Object -ExpandProperty Name | ForEach-Object {
                                    
    #                                 $HostObject = $InputObject | Where-Object HostName -match $($_)
    #                                 $ESXiHost   = $($HostObject.HostName).Split('.')[0]

    #                                 if($HostObject.ConnectionState -eq 'Connected'){
    #                                     $prefix = '+'
    #                                 }elseif($HostObject.ConnectionState -match 'New'){
    #                                     $prefix = 'o'
    #                                 }else{
    #                                     $prefix = '-'
    #                                 }

    #                                 "VC$($vcNo)C$($ClusterNo)M$($ModelNo)_$($Datacenter) : $($prefix) $($ESXiHost), ESXi $($HostObject.Version), $($RootModel)" | Add-Content $OutFile -Encoding utf8
    #                             }
    #                             #endregion HostName
                                
    #                         }
    #                         #endregion Datacenter
                        
    #                         $ModelNo = 0
    #                     }
    #                     #endregion Group Model
    #                 }
    #             }

    #             $ClusterNo = 0
    #             #endregion Group Cluster

    #             if($Markdown){
    #                 "`````````n" | Add-Content $OutFile -Encoding utf8
    #                 "[Top](#)`n" | Add-Content $OutFile -Encoding utf8
    #             }else{
    #                 '</div><p><button class="button"><a href="#">Top</a></button></p>' | Add-Content $OutFile -Encoding utf8
    #             }
    #         }
    #     }
    #     #endregion Group vCenter

    # }catch{
    #     Write-Warning $('ScriptName:', $($_.InvocationInfo.ScriptName), 'LineNumber:', $($_.InvocationInfo.ScriptLineNumber), 'Message:', $($_.Exception.Message) -Join ' ')
    #     $error.Clear()
    # }

}

end{
    if($Markdown){
        "---`n" | Add-Content $OutFile -Encoding utf8
        "I $([char]9829) PS > Diagram created with PowerShell and Mermaid at $((Get-Date).ToString())`n" | Add-Content $OutFile -Encoding utf8
        "---" | Add-Content $OutFile -Encoding utf8
    }else{
        $Html | Set-Content $OutFile -Encoding utf8
    }

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', $function -Join ' ')
    $TimeSpan  = New-TimeSpan -Start $StartTime -End (Get-Date)
    $Formatted = $TimeSpan | ForEach-Object {
        '{1:0}h {2:0}m {3:0}s {4:000}ms' -f $_.Days, $_.Hours, $_.Minutes, $_.Seconds, $_.Milliseconds
    }
    Write-Verbose $('Finished in:', $Formatted -Join ' ')

    Start-Process $($OutFile)
    return $($OutFile)
}
