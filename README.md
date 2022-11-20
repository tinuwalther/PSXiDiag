# PsMmDiagram

Create Mermaid Diagram with PowerShell

## Class Diagram

Create a Class Diagram from a CSV-File base on a VMware ESXiHost Inventory.

### Markdown Diagram

Import-Csv with the Semicolon-Delimiter and create the Mermaid-Diagram with the content of the CSV and the Title 'ESXiHost Inventory' as Markdown:

````
.\bin\New-vCenterDiagram.ps1 -InputObject (Import-Csv -Path ..\data\inventory.csv -Delimiter ';') -Title 'ESXiHost Inventory'
````

![New-vCenterDiagram](./img/PsMmDiagram-md.png)

### HTML Diagram

Import-Csv with the Semicolon-Delimiter and create the Mermaid-Diagram with the content of the CSV and the Title 'ESXiHost Inventory' as Html.

````
.\bin\New-vCenterDiagram.ps1 InputObject (Import-Csv -Path ..\data\inventory.csv -Delimiter ';') -Title 'ESXiHost Inventory' -Title 'ESXiHost Inventory' -Html
````

![New-vCenterDiagram](./img/PsMmDiagram-html.png)
