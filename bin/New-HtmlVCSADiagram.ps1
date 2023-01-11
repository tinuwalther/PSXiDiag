<#
.SYNOPSIS
    New-HtmlVCSADiagram.ps1

.DESCRIPTION
    New-HtmlVCSADiagram - Create a Mermaid Class Diagram.

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
    
.PARAMETER RelationShip
    Specify a valid RelationShip.
    
.PARAMETER Title
    Specify a valid Title for the Website.
    
.EXAMPLE
    .\New-HtmlVCSADiagram.ps1 -InputObject (Import-Csv -Path ..\data\inventory.csv -Delimiter ';') -Title 'HTML ESXiHost Inventory'

    Import-Csv with the Semicolon-Delimiter and create the Mermaid-Diagram with the content of the CSV and the Title 'HTML ESXiHost Inventory' as Html.

.EXAMPLE
    .\New-HtmlVCSADiagram.ps1 -InputObject (Get-Content ..\data\Inventory.json | ConvertFrom-Json) -Title 'HTML ESXiHost Inventory'

    Import from a JSON-File and create the Mermaid-Diagram with the content of the CSV and the Title 'HTML ESXiHost Inventory' as Html.

#>

[CmdletBinding()]
param (
    [Parameter(
        Mandatory=$true,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true,
        Position = 0
    )]
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

    # for file only
    $OutFile = (Join-Path -Path $($PSScriptRoot).Replace('bin','output') -ChildPath "$($Title).html") -replace '\s', '-'

    # for Pode Server
    # $PodePath = Join-Path -Path $($PSScriptRoot).Replace('bin','pode') -ChildPath 'views'
    # $PodeView = (("$($Title).html") -replace '\s', '-')
    # $OutFile  = Join-Path -Path $($PodePath) -ChildPath $($PodeView)
    Write-Verbose "OutFile: $($OutFile)"

    #region HTML Definition
    function New-CSS{
        [CmdletBinding()]
        param ()

        $function = $($MyInvocation.MyCommand.Name)
        foreach($item in $PSBoundParameters.keys){
            $params = "$($params) -$($item) $($PSBoundParameters[$item])"
        }
        Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Process ]', "$($function)$($params)" -Join ' ')
    
@"
<style> 
    body { 
        margin:0;
        background: #212529 !important;
        text-align: center; 
        font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,"Noto Sans",sans-serif,"Apple Color Emoji","Segoe UI Emoji","Segoe UI Symbol","Noto Color Emoji"
    }

    .header {
        background: #033b63;
        padding: 30px;
        color: #e9ecef;
        font-family: "QuickSand", sans-serif;
        font-size: medium;
        text-align: center; 
        display: block;
        overflow-y: hidden;
        margin-top: 20px;
        margin-bottom: 10px;
        margin-left: 0px;
        margin-right: 0px;
    }

    /* Style the top navigation bar */
    .topnav {
        overflow: hidden;
        background-color: #333;
    }

    /* Style the topnav links */
    .topnav a {
        float: left;
        display: block;
        color: #f2f2f2;
        text-align: center;
        font-size: 16px;
        font-family: "QuickSand", sans-serif;
        padding: 14px 16px;
        text-decoration: none;
    }

    /* Change color on hover */
    .topnav a:hover {
        background-color: #ddd;
        color: black;
    }

    ul {
        list-style-type: none;
        margin: 0;
        padding: 0;
        overflow: hidden;
        background-color: #333;
        position: fixed;
        top: 0;
        width: 100%;
    }
      
    li {
        float: left;
    }
      
    .active {
        background-color: #4CAF50;
    }
      
    li a {
        display: block;
        color: white;
        text-align: center;
        padding: 14px 16px;
        text-decoration: none;
    }

    div {
        text-align: center; 
        color: #e9ecef;
    }

    article {
        padding: 20px;
        background: #034f84;
        text-align: center;
    }

    #Content {
        padding: 20px;
        background: #034f84;
        text-align: center; 
    }

    .footer {
        padding: 10px;
        text-align: center;
    }

    hr {
        border: 1px solid gray;
    }

    p {
        font-family: "QuickSand", sans-serif;
        text-align: center; 
    }

    h1 {
        font-family: "QuickSand", sans-serif;
        margin-top: 40px;
        margin-bottom: 40px;
        text-align: center; 
        font-size:2.5rem;
    }

    h2 {
        font-family: "QuickSand", sans-serif;
        margin-top: 40px;
        margin-bottom: 30px;
        text-align: center; 
        font-size:2rem;
    }

    h3 {
        font-family: "QuickSand", sans-serif;
        margin-top: 20px;
        margin-bottom: 10px;
        text-align: center; 
        font-size:1.75rem;
    }

    h4 {
        font-family: "QuickSand", sans-serif;
        margin-top: 10px;
        margin-bottom: 60px;
        text-align: center; 
        font-size:1.5rem
    }

    a:link {
        color: green;
        text-decoration: none;
    }

    /* visited link */
    a:visited {
        color: lightgreen;
    }

    /* mouse over link */
    a:hover {
        color: hotpink;
    }

    /* selected link */
    a:active {
        color: darkgreen;
    }

    /* Create three equal columns that float next to each other */
    .column-left {
        float: left;
        width: 20%;
    }
    .column-middle {
        float: left;
        width: 60%;
    }
    .column-right {
        float: left;
        width: 20%;
    }
</style>
"@
    }

    function New-Html{
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)]
            [String]$Page,

            [Parameter(Mandatory=$true)]
            [String]$Title,

            [Parameter(Mandatory=$true)]
            [String]$BodyDescription,

            [Parameter(Mandatory=$true)]
            [String]$OutFile,

            [Parameter(Mandatory=$true)]
            [String]$css
        )

        $function = $($MyInvocation.MyCommand.Name)
        foreach($item in $PSBoundParameters.keys){
            $params = "$($params) -$($item) $($PSBoundParameters[$item])"
        }
        Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Process ]', "$($function)$($params)" -Join ' ')

$head = @"
<head>
    <title>$($Page)</title>
    $css
    <script src="https://cdnjs.cloudflare.com/ajax/libs/mermaid/9.2.2/mermaid.min.js"></script>
    <script>mermaid.initialize({startOnLoad:true});</script>
</head>
"@

$header = @"
<header>
    <div class="header">
        <h1>$($Page)</h1>
        <h2>$($Title)</h2>
        <p>$($BodyDescription)</p>
    </div>
</header>
"@

$footer = @"
    <div class="footer">
        <div class="column-left">
            <p><a href="#">I $([char]9829) PS ></a></p>
        </div>
        <div class="column-middle">
            <p>Diagram created with PowerShell and Mermaid</p>
            <p>Report saved as $($OutFile)</p>
        </div>
        <div class="column-right">
            <p>$((Get-Date).ToString())</p>
        </div>
    </div>
</body>
</html>
"@

        [PSCustomObject]@{
            head   = $head
            header = $header
            footer = $footer
        }

    }
    #endregion HTML

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Process ]', $function -Join ' ')

    #region import Html code
    $Parameter = @{
        Page            = $Page
        Title           = $Title
        BodyDescription = 'PsMmaDiagram builds Mermaid Diagrams with PowerShell as HTML-Files from an object of VMware ESXiHosts'
        OutFile         = $OutFile
        Css             = (New-CSS)
    }
    $HtmlDefinition = New-HTML @Parameter
    #endregion

    try{

        $HtmlOut = @()
        #region HTML Header
        $HtmlOut += '<!doctype html><html lang="en">'
        $HtmlOut += $HtmlDefinition.head
        $HtmlOut += "<body>"
        $HtmlOut += $HtmlDefinition.header
        #endregion

        #region vCenterServer Nav Links
        $HtmlOut += '<div class="topnav">'
        $HtmlOut += '<ul>'
        $HtmlOut += '<li><a class="active" href="#"><b>HOME</b></a></li>'
        $GroupVC = $InputObject | Group-Object $Column.Field01 | Select-Object -ExpandProperty Name
        $GroupVC | ForEach-Object {
            $vCenter = $($_).Split('.')[0]
            if(-not([String]::IsNullOrEmpty($vCenter))){
                $HtmlOut += "<li><a href='#$($vCenter)'><b>$vCenter</b></a></li>"
                Write-Verbose $_
            }
        }
        $HtmlOut += '</ul></div>'
        #endregion

        #region Group vCenter
        $GroupVC | ForEach-Object {

            $vcNo ++
            $vCenter = $($_).Split('.')[0]
            if(-not([String]::IsNullOrEmpty($vCenter))){
                Write-Verbose "vCenter: $($_)"

                #region article
                $HtmlOut += '<article>'
                $HtmlOut += "<h3 id='$($vCenter)'><a href='https://$($_)/ui' target='_blank'>vCenter $($vCenter)</a></h3><br><hr><br>"

                #region ESXiHosts
                $HtmlOut += '<article><div>'  
                $InputObject | Where-Object $Column.Field01 -match $_ | Group-Object vCenterServer | ForEach-Object {
                    $CountOfVersion = $_.Group.Version | Group-Object | ForEach-Object {
                        "$($_.Name) = $($_.Count)"
                    }
                    $HtmlOut += "Total ESXiHosts in $($vCenter): $($_.Count) (ESXi Versions: $($CountOfVersion -join ', '))"
                }
                $HtmlOut += '</div></article>'
                #endregion

                #region Mermaid
                $HtmlOut += '<div class="mermaid">'
                $HtmlOut += 'classDiagram'
                #endregion

                #region Group Cluster
                $InputObject | Where-Object $Column.Field01 -match $_ | Group-Object $Column.Field02 | Select-Object -ExpandProperty Name | ForEach-Object {
                    if(-not([String]::IsNullOrEmpty($_))){

                        Write-Verbose "Cluster: $($_)"

                        $ClusterNo ++
                        $RootCluster = $_
                        $FixCluster  = $RootCluster -replace '-'

                        $HtmlOut += "VC$($vcNo)_$($vCenter) $($RelationShip) VC$($vcNo)C$($ClusterNo)_$($FixCluster)"
                        $HtmlOut += "VC$($vcNo)_$($vCenter) : + $($RootCluster)"
        
                        #region Group Model
                        $InputObject | Where-Object $Column.Field01 -match $vCenter | Where-Object $Column.Field02 -match $RootCluster | Group-Object $Column.Field03 | Select-Object -ExpandProperty Name | ForEach-Object {
                            
                            Write-Verbose "Model: $($_)"

                            $ModelNo ++
                            $RootModel = $_
                            $FixModel  = $RootModel -replace '-' -replace '\(' -replace '\)'

                            $HtmlOut += "VC$($vcNo)C$($ClusterNo)_$($FixCluster) : + $($RootModel)"
        
                            $HtmlOut +=  "VC$($vcNo)C$($ClusterNo)_$($FixCluster) $($RelationShip) VC$($vcNo)C$($ClusterNo)_$($FixModel)"
                                    
                            #region Group PhysicalLocation
                            $InputObject | Where-Object $Column.Field01 -match $vCenter | Where-Object $Column.Field02 -match $RootCluster | Where-Object $Column.Field03 -match $RootModel | Group-Object $Column.Field04 | Select-Object -ExpandProperty Name | ForEach-Object {

                                Write-Verbose "PhysicalLocation $($_)"
                                $PhysicalLocation = $_
                                $ObjectCount = $InputObject | Where-Object $Column.Field01 -match $vCenter | Where-Object $Column.Field02 -match $RootCluster | Where-Object $Column.Field03 -match $RootModel | Where-Object $Column.Field04 -match $PhysicalLocation | Select-Object -ExpandProperty $Column.Field05

                                $HtmlOut += "VC$($vcNo)C$($ClusterNo)_$($FixModel) : - $($PhysicalLocation), $($ObjectCount.count) ESXi Hosts"

                                $HtmlOut += "VC$($vcNo)C$($ClusterNo)_$($FixModel) $($RelationShip) VC$($vcNo)C$($ClusterNo)_$($PhysicalLocation)"

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

                                    $HtmlOut += "VC$($vcNo)C$($ClusterNo)_$($PhysicalLocation) : $($prefix) $($ESXiHost), ESXi $($HostObject.Version), $($RootModel)"
                                }
                                #endregion HostName
                                
                            }
                            #endregion PhysicalLocation
                            $ModelNo = 0
                        }
                        #endregion Group Model

                    }
                }
                #endregion Group Cluster
                $ClusterNo = 0

                $HtmlOut += "</article>"
                #endregion article
            }

        }
        #endregion Group vCenter

        #region ESXiHosts
        $HtmlOut += '<article><div><hr>'
        $CountOfVersion = $InputObject | Group-Object Version | ForEach-Object {
            "$($_.Name) = $($_.Count)"
        }
        $HtmlOut += "Total ESXiHosts: $(($InputObject.$($Column.Field01)).count) (ESXi Versions: $($CountOfVersion -join ', '))"
        $HtmlOut += '</div></article>'
        #endregion

        $HtmlOut | Set-Content $OutFile -Encoding utf8

        if($CurrentOS -eq [OSType]::Windows){
            Start-Process $($OutFile)
        }else{
            Start-Process "file://$($OutFile)"
        }

    }catch{
        Write-Warning $('ScriptName:', $($_.InvocationInfo.ScriptName), 'LineNumber:', $($_.InvocationInfo.ScriptLineNumber), 'Message:', $($_.Exception.Message) -Join ' ')
        $error.Clear()
    }

}

end{
    $HtmlDefinition.footer

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', $function -Join ' ')
    $TimeSpan  = New-TimeSpan -Start $StartTime -End (Get-Date)
    $Formatted = $TimeSpan | ForEach-Object {
        '{1:0}h {2:0}m {3:0}s {4:000}ms' -f $_.Days, $_.Hours, $_.Minutes, $_.Seconds, $_.Milliseconds
    }
    Write-Verbose $('Finished in:', $Formatted -Join ' ')

    return $($OutFile)
}