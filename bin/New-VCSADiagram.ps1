<#
.SYNOPSIS
    New-VCSADiagram.ps1

.DESCRIPTION
    New-VCSADiagram - Create a Mermaid Class Diagram.

.EXAMPLE
    .\PSXiDiag\bin\New-VCSADiagram.ps1 -InputObject (Import-Csv -Path .\PSXiDiag\data\inventory.csv -Delimiter ';') -Title 'Markdown ESXiHost Inventory'

    Import-Csv with the Semicolon-Delimiter and create the Mermaid-Diagram with the content of the Object and the Title 'Markdown ESXiHost Inventory' as Markdown.

.EXAMPLE
    .\PSXiDiag\bin\New-VCSADiagram.ps1 -InputObject (Import-Csv -Path .\PSXiDiag\data\inventory.csv -Delimiter ';') -Title 'HTML ESXiHost Inventory' -Html

    Import-Csv with the Semicolon-Delimiter and create the Mermaid-Diagram with the content of the Object and the Title 'HTML ESXiHost Inventory' as Html.

.EXAMPLE
    .\PSXiDiag\bin\New-VCSADiagram.ps1 -InputObject (Import-Csv -Path .\PSXiDiag\data\inventory.csv -Delimiter ';') -Title 'PSHTML ESXiHost Inventory' -Pshtml

    Import-Csv with the Semicolon-Delimiter and create the Mermaid-Diagram with the content of the Object and the Title 'PSHTML ESXiHost Inventory' as Html.

.EXAMPLE
    .\PSXiDiag\bin\New-VCSADiagram.ps1 -InputObject (Import-Csv -Path .\PSXiDiag\data\inventory.csv -Delimiter ';') -Title 'DrawIO ESXiHost Inventory' -DrawIO

    Import-Csv with the Semicolon-Delimiter and create the Draw.IO CSV with the content of the Object and the Title 'DrawIO ESXiHost Inventory' as CSV.

#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [Object]$InputObject,

    [Parameter(Mandatory=$true)]
    [String]$Title,

    [Parameter(Mandatory=$false)]
    [Switch]$Html,

    [Parameter(Mandatory=$false)]
    [Switch]$Pshtml,

    [Parameter(Mandatory=$false)]
    [Switch]$DrawIo
)

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

Write-Host "Running Scrip:", $MyInvocation.MyCommand, "on $($CurrentOS)" -ForegroundColor Green

if($Html){
    $CommandToExecute = $(Join-Path -Path $PSScriptRoot -ChildPath 'New-HtmlVCSADiagram.ps1')
}elseif($Pshtml){
    $CommandToExecute = $(Join-Path -Path $PSScriptRoot -ChildPath 'New-PshtmlVCSADiagram.ps1')
}elseif($DrawIo){
    $CommandToExecute = $(Join-Path -Path $PSScriptRoot -ChildPath 'New-DrawIOVCSACsv.ps1')
}else{
    $CommandToExecute = $(Join-Path -Path $PSScriptRoot -ChildPath 'New-MarkdownVCSADiagram.ps1')
}

& $CommandToExecute -InputObject $InputObject -Title $Title