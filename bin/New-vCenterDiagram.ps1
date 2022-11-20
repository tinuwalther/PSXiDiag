<#
.SYNOPSIS
    New-vCenterDiagram.ps1

.DESCRIPTION
    New-vCenterDiagram - Create a Mermaid Class Diagram.

.PARAMETER InputObject
    Specify a valid InputObject.
    
.PARAMETER RelationShip
    Specify a valid RelationShip.
    
.PARAMETER Title
    Specify a valid Title for the Website.
    
.PARAMETER Html
    Switch, if omitted the Output is saved as Markdown-File else as HTML-File.
    
.EXAMPLE
    .\New-vCenterDiagram.ps1 -InputObject (Import-Csv -Path ..\data\inventory.csv -Delimiter ';') -Title 'ESXiHost Inventory'

    Import-Csv with the default Delimiter and create the Mermaid-Diagram with the content of the CSV and the Title 'ESXiHost Inventory' as Markdown.

.EXAMPLE
    .\New-vCenterDiagram.ps1 -InputObject (Import-Csv -Path ..\data\inventory.csv -Delimiter ';') -Title 'ESXiHost Inventory' -Html

    Import-Csv with the Semicolon-Delimiter and create the Mermaid-Diagram with the content of the CSV and the Title 'ESXiHost Inventory' as Html.

.EXAMPLE
    .\New-vCenterDiagram.ps1 -InputObject (Get-Content ..\data\Inventory.json | ConvertFrom-Json) -Title 'ESXiHost Inventory' -Title 'ESXiHost Inventory' -Html

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
h1 {
    text-align: center; 
    color: white;
} 

h2 {
    text-align: center; 
    color: white;
}

h3 {
    text-align: center; 
    color: white;
}

p {
    text-align: center; 
    color: white;
}    

a {
    text-align: center; 
    color: white;
}

div {
    text-align: center; 
    color: white;
}

header {
    background-color: #033b63;
    padding: 30px;
    text-align: center;
    font-size: 30px;
    color: white;
}

nav {
    background-color: 033b63;
    text-align: center;
}

body {
    background-color: #034f84;
    font-family: Verdana;
    opacity: 0.9;
    text-align: center;
}

footer {
    background-color: #033b63;
    font-size: 13px;
    padding: 10px;
}

.button-small {
    background-color: #4CAF50;
    border: none;
    color: white;
    padding: 8px 62px;
    text-align: center;
    text-decoration: none;
    display: inline-block;
    font-size: 13px;
    margin: 4px 2px;
    cursor: pointer;
}

.button {
    background-color: #4CAF50;
    border: none;
    color: white;
    padding: 13px 62px;
    text-align: center;
    text-decoration: none;
    display: inline-block;
    font-size: 16px;
    margin: 4px 2px;
    cursor: pointer;
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
    <script src="https://cdnjs.cloudflare.com/ajax/libs/mermaid/8.13.4/mermaid.min.js"></script>
    <script>mermaid.initialize({startOnLoad:true});</script>
</head>
"@

$header = @"
<header>
    <h1>$($Page)</h1>
    <p>$($Title)</p>
</header>
"@

$footer = @"
<footer>
    <p>I $([char]9829) PS > Diagram created with PowerShell and Mermaid at $((Get-Date).ToString())</p>
    <p>Report saved as $($OutFile)</p>
</footer>

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
    #Join-Path -Path $($PSScriptRoot).Trim('bin') -ChildPath ("$($BaseInputFile).html")

    if($Html){
        $OutFile = Join-Path -Path $($PSScriptRoot).Trim('bin') -ChildPath $($($MyInvocation.MyCommand.Name) -replace '.ps1', '.html')
        Write-Verbose $OutFile
    }else{
        $OutFile = Join-Path -Path $($PSScriptRoot).Trim('bin') -ChildPath $($($MyInvocation.MyCommand.Name) -replace '.ps1', '.md')
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
        if($html){'<nav>' | Add-Content $OutFile -Encoding utf8}
        $GroupVC = $InputObject | Group-Object vCenterServer | Select-Object -ExpandProperty Name
        $GroupVC | ForEach-Object {
            $vCenter = $($_).Split('.')[0]
            if(-not([String]::IsNullOrEmpty($vCenter))){
                if($html){
                    "<button class='button-small'><a href='#$($vCenter)'><b>$vCenter</b></a></button>" | Add-Content $OutFile -Encoding utf8 -Force
                    Write-Verbose $_
                }else{
                    "- [vCenter $($vCenter)](#vcenter-$($vCenter))" | Add-Content $OutFile -Encoding utf8
                }
            }
        }
        if($html){'</nav>' | Add-Content $OutFile -Encoding utf8}
        #endregion

        #region Group vCenter
        $GroupVC | ForEach-Object {

            $vcNo ++
            $vCenter = $($_).Split('.')[0]
            if(-not([String]::IsNullOrEmpty($vCenter))){
                Write-Verbose "vCenter: $($_)"

                #region section header
                if($html){
                    "<hr><h3 id='$($vCenter)'><a href='https://$($_)/ui' target='_blank'>vCenter $($vCenter)</a></h3><hr>" | Add-Content $OutFile -Encoding utf8
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
                            #"VC$($vcNo)C$($ClusterNo)_$($Cluster) : Get-Model()" | Add-Content $OutFile -Encoding utf8
        
                            "VC$($vcNo)C$($ClusterNo)_$($FixCluster) $($RelationShip) VC$($vcNo)C$($ClusterNo)M$($ModelNo)_$($FixModel)" | Add-Content $OutFile -Encoding utf8
                            #"VC$($vcNo)C$($ClusterNo)_$($Model) : Get-Datacenter()" | Add-Content $OutFile -Encoding utf8
                                    
                            #region Group Datacenter
                            $InputObject | Where-Object vCenterServer -match $vCenter | Where-Object Cluster -match $RootCluster | Where-Object Model -match $RootModel | Group-Object Datacenter | Select-Object -ExpandProperty Name | ForEach-Object {

                                Write-Verbose "Datacenter $($_)"
                                $Datacenter = $_
                                
                                "VC$($vcNo)C$($ClusterNo)M$($ModelNo)_$($FixModel) $($RelationShip) VC$($vcNo)C$($ClusterNo)M$($ModelNo)_$($Datacenter)" | Add-Content $OutFile -Encoding utf8

                                #region Group HostName
                                $InputObject | Where-Object vCenterServer -match $vCenter | Where-Object Model -match $RootModel | Where-Object Datacenter -match $Datacenter | Group-Object HostName | Select-Object -ExpandProperty Name | ForEach-Object {
                                    
                                    $HostObject = $InputObject | Where-Object HostName -match $($_)
                                    $ESXiHost   = $($HostObject.HostName).Split('.')[0]

                                    if($HostObject.ConnectionState -eq 'Connected'){
                                        $prefix = '+'
                                    }else{
                                        $prefix = '-'
                                    }

                                    "VC$($vcNo)C$($ClusterNo)M$($ModelNo)_$($Datacenter) : $($prefix) $($ESXiHost), ESXi $($HostObject.Version), $($RootModel)" | Add-Content $OutFile -Encoding utf8
                                }
                                #endregion HostName
                                
                            }
                            #endregion Datacenter
                        
                            $ModelNo = 0
                        }
                        #endregion Group Model
                    }
                }

                $ClusterNo = 0
                #endregion Group Cluster

                if($html){
                    '</div><p><button class="button"><a href="#">Top</a></button></p>' | Add-Content $OutFile -Encoding utf8
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
