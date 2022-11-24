# PsMmaDiagram

PsMmaDiagram builds Mermaid Diagrams with PowerShell and save it as Markdown- or HTML-File.

 - [Markdown Class Diagram](#markdown-class-diagram)
 - [HTML Class Diagram](#html-class-diagram)
 - [PSHTML Class Diagram](#pshtml-class-diagram)

## Markdown Class Diagram

Build a simple Class Diagram from an object of VMware ESXiHosts.

![New-SimpleVCSADiagram](./img/PsMmDiagram-md.png)

Import the data from a CSV-file and create a Mermaid-Class-Diagram with the content of the object and save it as Markdown.

- Semicolon-Delimiter
- Title 'Markdown ESXiHost Inventory'

````PowerShell
Set-Location .\PsMmaDiagram\bin
$Parameters = @{
    InputObject = Import-Csv -Path ..\data\inventory.csv -Delimiter ';'
    Title       = 'Markdown ESXiHost Inventory'
}
.\New-SimpleVCSADiagram.ps1 @Parameters
````

[Top](#)

## HTML Class Diagram

Build a simple Class Diagram from an object of VMware ESXiHosts.

![New-SimpleVCSADiagram](./img/PsMmDiagram-html.png)

Import the data from a CSV-file and create a Mermaid-Class-Diagram with the content of the object save it as Html.

- Semicolon-Delimiter
- Title 'HTML ESXiHost Inventory'

CSS and Html is inside the Html-Page and the Computer must have access to the Internet to mermaid.min.js to format the Diagrams.

````PowerShell
Set-Location .\PsMmaDiagram\bin
$Parameters = @{
    InputObject = Import-Csv -Path ..\data\inventory.csv -Delimiter ';'
    Title       = 'HTML ESXiHost Inventory'
    Html        = $true
}
.\New-SimpleVCSADiagram.ps1 @Parameters 
````

[Top](#)

## PSHTML Class Diagram

Build a simple Class Diagram from an object of VMware ESXiHosts. It use PSHTML and BootStrap for the layout of the Page.

![New-AdvancedVCSADiagram](./img/AdvPsMmDiagram-html.png)

Import the data from a CSV-file and create a Mermaid-Class-Diagram with the content of the object as Html with PSHTML.

All libraries are included in the project in the assets-folder and no access to the Internet is needed.

- Semicolon-Delimiter
- Title 'Advanced ESXiHost Inventory'

````PowerShell
Set-Location .\PsMmaDiagram\bin
$Parameters = @{
    InputObject = Import-Csv -Path ..\data\inventory.csv -Delimiter ';'
    Title       = 'PSHTML ESXiHost Inventory'
}
.\New-AdvancedVCSADiagram.ps1 @Parameters 
````

[Top](#)
