<#
.SYNOPSIS
    New-SimpleVCSADiagram.ps1

.DESCRIPTION
    New-SimpleVCSADiagram - Create a Mermaid Class Diagram.

.PARAMETER InputObject
    Specify a valid InputObject.
    
.PARAMETER RelationShip
    Specify a valid RelationShip.
    
.PARAMETER Title
    Specify a valid Title for the Website.
    
.PARAMETER Html
    Switch, if omitted the Output is saved as Markdown-File else as HTML-File.
    
.EXAMPLE
    .\New-SimpleVCSADiagram.ps1 -InputObject (Import-Csv -Path ..\data\inventory.csv -Delimiter ';') -Title 'Markdown ESXiHost Inventory'

    Import-Csv with the default Delimiter and create the Mermaid-Diagram with the content of the CSV and the Title 'Markdown ESXiHost Inventory' as Markdown.

.EXAMPLE
    .\New-SimpleVCSADiagram.ps1 -InputObject (Import-Csv -Path ..\data\inventory.csv -Delimiter ';') -Title 'HTML ESXiHost Inventory' -Html

    Import-Csv with the Semicolon-Delimiter and create the Mermaid-Diagram with the content of the CSV and the Title 'HTML ESXiHost Inventory' as Html.

.EXAMPLE
    .\New-SimpleVCSADiagram.ps1 -InputObject (Get-Content ..\data\Inventory.json | ConvertFrom-Json) -Title 'HTML ESXiHost Inventory' -Title 'ESXiHost Inventory' -Html

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
        background: #212529 !important;
        text-align: center; 
    }

    .header {
        background: #033b63;
        padding: 30px;
        color: #e9ecef;
        font-size: medium;
        text-align: center; 
        display: block;
        overflow: auto;
        overflow-y: hidden;
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
        color: #e9ecef;
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
    }

    h2 {
        font-family: "QuickSand", sans-serif;
        margin-top: 40px;
        margin-bottom: 30px;
        text-align: center; 
    }

    h3 {
        font-family: "QuickSand", sans-serif;
        margin-top: 20px;
        margin-bottom: 10px;
        text-align: center; 
    }

    h4 {
        font-family: "QuickSand", sans-serif;
        margin-top: 10px;
        margin-bottom: 60px;
        text-align: center; 
    }

    a:link {
        color: green;
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
        <p>PsMmaDiagram builds Mermaid Diagrams with PowerShell as HTML-Files from an object of VMware ESXiHosts</p>
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

    $vcNo = 0; $ClusterNo = 0; $ModelNo = 0
    $Page = $($MyInvocation.MyCommand.Name) -replace '.ps1'

    if($Html){
        $OutFile = Join-Path -Path $($PSScriptRoot).Trim('bin') -ChildPath "$($Title).html"
        Write-Verbose $OutFile
    }else{
        $OutFile = Join-Path -Path $($PSScriptRoot).Trim('bin') -ChildPath "$($Title).md"
        Write-Verbose $OutFile
    }
}

process{
    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Process ]', $function -Join ' ')

    #region import Html code
    if($Html){
        $HtmlDefinition = New-HTML -Page $Page -Title $Title -OutFile $OutFile -Css (New-CSS)
    }
    #endregion

    try{

        #region HTML/Markdown Header
        if($html){
            '<!doctype html><html lang="en">'  | Set-Content $OutFile -Encoding utf8
            $HtmlDefinition.head | Add-Content $OutFile -Encoding utf8 -Force
            "<body>" | Add-Content $OutFile -Encoding utf8 -Force
            $HtmlDefinition.header | Add-Content $OutFile -Encoding utf8 -Force
        }else{
            "# $($Header) - $($Title)`n" | Set-Content $OutFile -Encoding utf8 -Force
        }
        #endregion

        #region vCenterServer Nav Links
        if($html){'<div class="topnav">' | Add-Content $OutFile -Encoding utf8}
        if($html){"<a href='#'><b>HOME</b></a>" | Add-Content $OutFile -Encoding utf8}
        $GroupVC = $InputObject | Group-Object vCenterServer | Select-Object -ExpandProperty Name
        $GroupVC | ForEach-Object {
            $vCenter = $($_).Split('.')[0]
            if(-not([String]::IsNullOrEmpty($vCenter))){
                if($html){
                    "<a href='#$($vCenter)'><b>$vCenter</b></a>" | Add-Content $OutFile -Encoding utf8 -Force
                    Write-Verbose $_
                }else{
                    " - [vCenter $($vCenter)](`#vcenter-$(($vCenter).ToLower()))" | Add-Content $OutFile -Encoding utf8
                }
            }
        }
        if($html){'</div>' | Add-Content $OutFile -Encoding utf8}
        #endregion

        #region Group vCenter
        $GroupVC | ForEach-Object {

            $vcNo ++
            $vCenter = $($_).Split('.')[0]
            if(-not([String]::IsNullOrEmpty($vCenter))){
                Write-Verbose "vCenter: $($_)"

                #region section header
                if($html){
                    '<article>' | Add-Content $OutFile -Encoding utf8 -Force
                    "<h3 id='$($vCenter)'><a href='https://$($_)/ui' target='_blank'>vCenter $($vCenter)</a></h3><br><hr><br>" | Add-Content $OutFile -Encoding utf8
                    '<div class="mermaid">' | Add-Content $OutFile -Encoding utf8
                    'classDiagram' | Add-Content $OutFile -Encoding utf8
                }else{
                    "---`n" | Add-Content $OutFile -Encoding utf8
                    "## [vCenter $($vCenter)](https://$($_)/ui)`n" | Add-Content $OutFile -Encoding utf8
                    "---`n" | Add-Content $OutFile -Encoding utf8
            
                    "````````mermaid" | Add-Content $OutFile -Encoding utf8
                    "classDiagram"    | Add-Content $OutFile -Encoding utf8
                }
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

                if($html){
                    '</div><p><a href="#">Top</a></p>' | Add-Content $OutFile -Encoding utf8
                    "</article>" | Add-Content $OutFile -Encoding utf8 -Force
                }else{
                    "`````````n" | Add-Content $OutFile -Encoding utf8
                    "[Top](#)`n" | Add-Content $OutFile -Encoding utf8
                }
            }
        }
        #endregion Group vCenter

    }catch{
        Write-Warning $('ScriptName:', $($_.InvocationInfo.ScriptName), 'LineNumber:', $($_.InvocationInfo.ScriptLineNumber), 'Message:', $($_.Exception.Message) -Join ' ')
        $error.Clear()
    }

}

end{
    if($html){
        $HtmlDefinition.footer | Add-Content $OutFile -Encoding utf8
    }else{
        "---`n" | Add-Content $OutFile -Encoding utf8
        "I $([char]9829) PS > Diagram created with PowerShell and Mermaid at $((Get-Date).ToString())`n" | Add-Content $OutFile -Encoding utf8
        "---" | Add-Content $OutFile -Encoding utf8
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