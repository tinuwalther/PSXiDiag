<#
.SYNOPSIS
    New-DrawIoVCSACsv.ps1

.DESCRIPTION
    New-DrawIoVCSACsv - Create a CSV-file to import in Draw.IO.

.PARAMETER InputObject
    Specify a valid InputObject.
    
.PARAMETER RelationShip
    Specify a valid RelationShip.
    
.PARAMETER Title
    Specify a valid Title for the Website.

.EXAMPLE
    .\New-DrawIoVCSACsv.ps1 -InputObject (Import-Csv -Path ..\data\inventory.csv -Delimiter ';') -Title 'Draw.IO ESXiHost Inventory'

    Import-Csv with the default Delimiter and create the Mermaid-Diagram with the content of the CSV and the Title 'Draw.IO ESXiHost Inventory' as Markdown.

.EXAMPLE
    .\New-DrawIoVCSACsv.ps1 -InputObject (Get-Content ..\data\Inventory.json | ConvertFrom-Json) -Title 'Draw.IO ESXiHost Inventory'

    Import from a JSON-File and create the Mermaid-Diagram with the content of the CSV and the Title 'Draw.IO ESXiHost Inventory' as Html.

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

    $vcNo = 0; $ClusterNo = 0; $ModelNo = 0
    $Page = $($MyInvocation.MyCommand.Name) -replace '.ps1'
}

process{

    #Fields = HostName;Version;Manufacturer;Model;vCenterServer;Cluster;PhysicalLocation;ConnectionState

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Process ]', $function -Join ' ')

    #region section header
$header = @"
## **********************************************************
## Configuration
## **********************************************************
# labels: {"label1" : "%name%", "label2" : "%type%: %name%", "label3" : "%name% - %version%<br>%model%"}
# labelname: labeltype
# style: shape=%shape%;whiteSpace=wrap;html=1;rounded=1;fillColor=%fill%;opacity=80;
# namespace: csvimport-
# connect: {"from": "refs", "to": "id", "style": "curved=0;endArrow=none;endFill=0;fontSize=11;"}
# width: 160
# height: 70
# padding: 20
# ignore: refs,shape,labeltype,fill
# nodespacing: 20
# levelspacing: 20
# edgespacing: 20
## layout from https://jgraph.github.io/mxgraph/docs/js-api/files/layout/mxFastOrganicLayout-js.html
## layout: auto
## layout: [{"layout":"mxHierarchicalLayout","config":{"orientation":"south"}}]
# layout: [{"layout":"mxFastOrganicLayout","config":{"orientation":"south"}}]
## **********************************************************
## CSV Data
## **********************************************************
id,refs,type,name,model,version,labeltype,fill,shape
"@
    #endregion

    try{

        $shape = 'entity'
        $color_vcsa     = '#198754'
        $color_cluster  = '#ef2539'
        $color_model    = '#343a40'
        $color_location = '#FA6800'
        $color_esxi     = '#0050EF'

        #region Group vCenter
        $GroupVC = $InputObject | Group-Object vCenterServer | Select-Object -ExpandProperty Name
        $GroupVC | ForEach-Object {

            $vcNo ++
            $vCenter = $($_).Split('.')[0]
            if(-not([String]::IsNullOrEmpty($vCenter))){
                
                Write-Verbose "vCenter: $($vcNo) -> $($_)"
                $OutFile = Join-Path -Path $($PSScriptRoot).Replace('bin','data') -ChildPath "$($Title)-$($vCenter).csv"
                Write-Verbose $OutFile

                $header | Set-Content $OutFile -Encoding utf8 -Force

                #id,refs,type,name,model,version,labeltype,fill,shape
                #1,"2,3",vCenterServer,vCSA021,"Appliance","7.0.3",label1,#034f84
                "$($vcNo),"""",vCenterServer,VC$($vcNo)_$($vCenter),Appliance,"""",label1,$color_vcsa,$($shape)" | Add-Content $OutFile -Encoding utf8

                #region Group Cluster
                $InputObject | Where-Object vCenterServer -match $_ | Group-Object Cluster | Select-Object -ExpandProperty Name | ForEach-Object {
                    if(-not([String]::IsNullOrEmpty($_))){

                        $ClusterNo ++                        
                        $RootCluster = $_
                        $FixCluster  = $RootCluster -replace '-'

                        Write-Verbose "Cluster: $($vcNo)$($ClusterNo) -> $($_)"

                        #id,refs,type,name,model,version,labeltype,fill,shape
                        #2,"4,5,6",Cluster,Windows,"","",label1,#034f84
                        "$($vcNo)$($ClusterNo),$($vcNo),Cluster,VC$($vcNo)C$($ClusterNo)_$($RootCluster),"""","""",label1,$color_cluster,$($shape)" | Add-Content $OutFile -Encoding utf8
        
                        #region Group Model
                        $InputObject | Where-Object vCenterServer -match $vCenter | Where-Object Cluster -match $RootCluster | Group-Object Model | Select-Object -ExpandProperty Name | ForEach-Object {

                            $ModelNo ++
                            $RootModel = $_
                            $FixModel  = $RootModel -replace '-'
                            
                            Write-Verbose "Model: $($vcNo)$($ClusterNo)$($ModelNo) -> $($_)"

                            #id,refs,type,name,model,version,labeltype,fill,shape
                            #4,"7",Model,ProLiant DL380 Gen10,"","Gen10",label1,#034f84
                            "$($vcNo)$($ClusterNo)$($ModelNo),$($vcNo)$($ClusterNo),Model,VC$($vcNo)C$($ClusterNo)_$($RootModel),"""","""",label1,$color_model,$($shape)" | Add-Content $OutFile -Encoding utf8
                                    
                            #region Group PhysicalLocation
                            $InputObject | Where-Object vCenterServer -match $vCenter | Where-Object Cluster -match $RootCluster | Where-Object Model -match $RootModel | Group-Object PhysicalLocation | Select-Object -ExpandProperty Name | ForEach-Object {

                                $PhysicalLocationNo ++
                                $PhysicalLocation = $_

                                Write-Verbose "PhysicalLocation: $($vcNo)$($ClusterNo)$($ModelNo)$($PhysicalLocationNo) -> $($_)"

                                $ObjectCount = $InputObject | Where-Object vCenterServer -match $vCenter | Where-Object Cluster -match $RootCluster | Where-Object Model -match $RootModel | Where-Object PhysicalLocation -match $PhysicalLocation | Select-Object -ExpandProperty HostName

                                #id,refs,type,name,model,version,labeltype,fill,shape
                                #7,"10,11",PhysicalLocation,Ost,"","",label1,#034f84
                                "$($vcNo)$($ClusterNo)$($ModelNo)$($PhysicalLocationNo),$($vcNo)$($ClusterNo)$($ModelNo),PhysicalLocation,VC$($vcNo)C$($ClusterNo)_$($PhysicalLocation),"""","""",label1,$color_location,$($shape)" | Add-Content $OutFile -Encoding utf8

                                #region Group HostName
                                $InputObject | Where-Object vCenterServer -match $vCenter | Where-Object Cluster -match $RootCluster | Where-Object Model -match $RootModel | Where-Object PhysicalLocation -match $PhysicalLocation | Group-Object HostName | Select-Object -ExpandProperty Name | ForEach-Object {
                                    
                                    $HostNameNo ++
                                    Write-Verbose "HostName: $($vcNo)$($ClusterNo)$($ModelNo)$($PhysicalLocationNo)$($HostNameNo) -> $($_)"

                                    $HostObject = $InputObject | Where-Object HostName -eq $($_)
                                    $ESXiHost   = $($HostObject.HostName).Split('.')[0]

                                    Write-Verbose $($HostObject | Out-String)

                                    if($HostObject.ConnectionState -eq 'Connected'){
                                        $prefix = '+'
                                    }elseif($HostObject.ConnectionState -match 'New'){
                                        $prefix = 'o'
                                    }else{
                                        $prefix = '-'
                                    }

                                    #id,refs,type,name,model,version,labeltype,fill,shape
                                    #10,"",ESXiHost,"ESXi7912","ProLiant DL380 Gen10","6.7",label3,#034f84
                                    "$($vcNo)$($ClusterNo)$($ModelNo)$($PhysicalLocationNo)$($HostNameNo),$($vcNo)$($ClusterNo)$($ModelNo)$($PhysicalLocationNo),ESXiHost,""$($prefix) $($ESXiHost)"",$($RootModel),$($HostObject.Version),label3,$($color_esxi),$($shape)" | Add-Content $OutFile -Encoding utf8
                                }
                                #endregion HostName
                                $HostNameNo = 0
                            }
                            #endregion PhysicalLocation
                            $PhysicalLocationNo = 0
                        }
                        #endregion Group Model
                        $ModelNo = 0
                    }
                }
                $ClusterNo = 0
                #endregion Group Cluster
            }
        }
        #endregion Group vCenter

        #Start-Process $($OutFile)

    }catch{
        Write-Warning $('ScriptName:', $($_.InvocationInfo.ScriptName), 'LineNumber:', $($_.InvocationInfo.ScriptLineNumber), 'Message:', $($_.Exception.Message) -Join ' ')
        $error.Clear()
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