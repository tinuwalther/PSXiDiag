<#
.SYNOPSIS
    New-PshtmlESXiDiag.ps1

.DESCRIPTION
    New-PshtmlESXiDiag - Create a Mermaid Class Diagram.

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
    
.PARAMETER AssetsPath
    Specify a valid AssetsPath for the Website.
    
.EXAMPLE
    .\New-PshtmlESXiDiag.ps1 -InputObject (Import-Csv -Path ..\data\inventory.csv -Delimiter ';') -Title 'PSHTML ESXiHost Inventory'

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
    .\New-PshtmlESXiDiag.ps1 @Parameters 

    Import from a JSON-File and create the Mermaid-Diagram with the content of the CSV and the Title 'PSHTML ESXiHost Inventory' as Html.

#>

#Requires -Modules PSHTML

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateScript({ if(Test-Path -Path $($_) ){$true}else{Throw "File '$($_)' not found"} })]
    [System.IO.FileInfo]$DBFile,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$SqlTableName,

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

    [Parameter(Mandatory=$false)]
    [String]$AssetsPath = '/assets' #'../assets' #$AssetsPath = $($PSScriptRoot).Replace('bin','assets')
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
    switch -Regex ($SqlTableName){
        'classic*' { $Title = 'Classic-ESXiHost-Diagram'}
        'cloud*'   { $Title = 'Cloud-ESXiHost-Diagram'}
    }

    $SqliteQuery = "Select * from $($SqlTableName)"
    $InputObject = Invoke-MySQLiteQuery -Path $DBFile.FullName -Query $SqliteQuery

    $vcNo = 0; $ClusterNo = 0; $ModelNo = 0
    $Page = ($($MyInvocation.MyCommand.Name) -replace '.ps1') + ' for Pode server'

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Process ]', $function -Join ' ')
    # for file only
    #$OutFile = (Join-Path -Path $($PSScriptRoot).Replace('bin','output') -ChildPath "$($Title).html") -replace '\s', '-'

    # for Pode Server
    $PodePath = Join-Path -Path $($PSScriptRoot).Replace('bin','pode') -ChildPath 'views'
    $PodeView = (("$($Title).html") -replace '\s', '-')
    $OutFile  = Join-Path -Path $($PodePath) -ChildPath $($PodeView)
    Write-Verbose "OutFile: $($OutFile)"
    
    Write-Verbose "AssetsPath: $($AssetsPath)"

    $ContinerStyleFluid  = 'container-fluid'

    #region header
    $HeaderTitle = $Page
    #endregion

    #region color
    $TextColor  = '#ccc'
    #region

    #region footer
    #$FooterSummary = "Report saved as $($OutFile)"
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
                    #DynamicLinks
                    $InputObject | Group-Object $Column.Field01 | Select-Object -ExpandProperty Name | ForEach-Object {
                        $vCenter = ($($_).Split('.')[0]).ToUpper()
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
            div -id "Content" -Class "$($ContinerStyleFluid)" -Style "background-color:#142440" {

                #region  <!-- article -->
                article -id "mermaid" -Content {

                    $vcNo ++
                    $vCenter = ($($_).Split('.')[0]).ToUpper()

                    if(-not([String]::IsNullOrEmpty($vCenter))){

                        h3 -Id $($vCenter) -Content {
                            a -href "https://$($_)/ui/" -Target _blank -content { "vCenter $($vCenter)" }
                        } -Style "text-align: center"
                        hr

                        #region ESXiHosts
                        $InputObject | Where-Object $Column.Field01 -match $_ | Group-Object vCenterServer | ForEach-Object {
                            $TotalESXiHost = span -class "badge bg-primary" -Content { "$($_.Count) ESXiHosts" }
                            $TotalCluster  = span -class "badge bg-info" -Content { "$($_.Group.Cluster | Group-Object | Measure-Object -Property Count | Select-Object -ExpandProperty Count) Cluster" }
                            $CountOfVersion = $_.Group.Version | Group-Object | ForEach-Object {
                                if($($_.Name) -match '^6.0'){
                                    span -class "badge bg-dark" -Content "$($_.Name) ($($_.Count))"
                                }
                                if($($_.Name) -match '^6.5'){
                                    span -class "badge bg-danger" -Content "$($_.Name) ($($_.Count))"
                                }
                                if($($_.Name) -match '^6.7'){
                                    span -class "badge bg-warning" -Content "$($_.Name) ($($_.Count))"
                                }
                                if($($_.Name) -match '^7'){
                                    span -class "badge bg-success" -Content "$($_.Name) ($($_.Count))"
                                }
                            }
                            p { 
                                "Total in $($vCenter):  $($TotalCluster) $($TotalESXiHost) $($CountOfVersion)"
                            } -Style "color:$TextColor" #f8f9fa
                        }
                        #endregion

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
                                        $FixModel  = $RootModel -replace '-' -replace '\(' -replace '\)'

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

        #region ESXiHosts
        hr
        div -id "Content" -Class "$($ContinerStyleFluid)" -Style "background-color:#142440" {
            article -id "ESXiHosts" -Content {
                $TotalESXiHost = span -class "badge bg-primary" -Content { "$(($InputObject.$($Column.Field01)).count) ESXiHosts" }
                $CountOfVersion = $InputObject | Group-Object Version | ForEach-Object {
                    if($($_.Name) -match '^6.0'){
                        span -class "badge bg-dark" -Content "$($_.Name) ($($_.Count))"
                    }
                    if($($_.Name) -match '^6.5'){
                        span -class "badge bg-danger" -Content "$($_.Name) ($($_.Count))"
                    }
                    if($($_.Name) -match '^6.7'){
                        span -class "badge bg-warning" -Content "$($_.Name) ($($_.Count))"
                    }
                    if($($_.Name) -match '^7'){
                        span -class "badge bg-success" -Content "$($_.Name) ($($_.Count))"
                    }
                }
                p {
                    "Total: $($TotalESXiHost) $($CountOfVersion)"
                } -Style "color:$TextColor" #f8f9fa
            }
        }
        #endregion

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

            #region <!-- section -->
            section -id "section" -Content {  

                Invoke-Command -ScriptBlock $navbar

                #region <!-- column -->
                div -Class "$($ContinerStyleFluid)" -Style "background-color:#142440" {
                
                    Invoke-Command -ScriptBlock $article

                }
                #endregion column

            }
            #endregion section
            
        }
        #endregion body

        #region footer
        div -Class $ContinerStyleFluid  {
            Footer {

                div -Class $ContinerStyleFluid {
                    div -Class "row align-items-center" {
                        div -Class "col-md" {
                            p {
                                a -href "#" -content { "I $([char]9829) PS >" }
                            }
                        }
                        div -Class "col-md" {
                            #p {$FooterSummary}
                        }
                        div -Class "col-md" {
                            p {$((Get-Date).ToString())}
                        } -Style "color:$TextColor"
                    }
                }
        
            }
        }
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
    "Diargam created: $($OutFile)"
}
