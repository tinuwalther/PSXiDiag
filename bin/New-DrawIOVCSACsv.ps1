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
## labels: %name%
# labels: {"label1" : "%name%", "label2" : "%type%: %name%", "label3" : "%name% - %version% - %model%"}
# labelname: labeltype
# style: whiteSpace=wrap;html=1;rounded=1;fillColor=#034f84;strokeColor=#000000;
# namespace: csvimport-
# connect: {"from": "refs", "to": "id", "style": "curved=0;endArrow=none;endFill=0;fontSize=11;"}
# width: auto
# height: auto
# padding: 40
# ignore: refs
# nodespacing: 60
# levelspacing: 100
# edgespacing: 40
# layout: verticaltree
## **********************************************************
## CSV Data
## **********************************************************
id,refs,type,name,model,version,labeltype
"@
    #endregion

    try{

        #region Group vCenter
        $GroupVC = $InputObject | Group-Object vCenterServer | Select-Object -ExpandProperty Name
        $GroupVC | ForEach-Object {

            $vcNo ++
            $vCenter = $($_).Split('.')[0]
            if(-not([String]::IsNullOrEmpty($vCenter))){
                
                Write-Verbose "vCenter: $($vcNo) -> $($_)"
                $OutFile = Join-Path -Path $($PSScriptRoot).Trim('bin') -ChildPath "$($Title)-$($vCenter).csv"
                Write-Verbose $OutFile

                $header | Set-Content $OutFile -Encoding utf8 -Force

                #id,refs,type,name,model,version,labeltype
                #1,"2,3",vCenterServer,vCSA021,"Appliance","7.0.3",label1
                "$($vcNo),"""",vCenterServer,$($vCenter),Appliance,"""",label1" | Add-Content $OutFile -Encoding utf8

                #region Group Cluster
                $InputObject | Where-Object vCenterServer -match $_ | Group-Object Cluster | Select-Object -ExpandProperty Name | ForEach-Object {
                    if(-not([String]::IsNullOrEmpty($_))){

                        $ClusterNo ++                        
                        $RootCluster = $_
                        $FixCluster  = $RootCluster -replace '-'

                        Write-Verbose "Cluster: $($vcNo)$($ClusterNo) -> $($_)"

                        #id,refs,type,name,model,version,labeltype
                        #2,"4,5,6",Cluster,Windows,"","",label2
                        "$($vcNo)$($ClusterNo),$($vcNo),Cluster,$($RootCluster),"""","""",label2" | Add-Content $OutFile -Encoding utf8
        
                        #region Group Model
                        $InputObject | Where-Object vCenterServer -match $vCenter | Where-Object Cluster -match $RootCluster | Group-Object Model | Select-Object -ExpandProperty Name | ForEach-Object {

                            $ModelNo ++
                            $RootModel = $_
                            $FixModel  = $RootModel -replace '-'
                            
                            Write-Verbose "Model: $($vcNo)$($ClusterNo)$($ModelNo) -> $($_)"

                            #id,refs,type,name,model,version,labeltype
                            #4,"7",Model,ProLiant DL380 Gen10,"","Gen10",label1
                            "$($vcNo)$($ClusterNo)$($ModelNo),$($vcNo)$($ClusterNo),Model,$($RootModel),"""","""",label1" | Add-Content $OutFile -Encoding utf8
                                    
                            #region Group PhysicalLocation
                            $InputObject | Where-Object vCenterServer -match $vCenter | Where-Object Cluster -match $RootCluster | Where-Object Model -match $RootModel | Group-Object PhysicalLocation | Select-Object -ExpandProperty Name | ForEach-Object {

                                $PhysicalLocationNo ++
                                $PhysicalLocation = $_

                                Write-Verbose "PhysicalLocation: $($vcNo)$($ClusterNo)$($ModelNo)$($PhysicalLocationNo) -> $($_)"

                                $ObjectCount = $InputObject | Where-Object vCenterServer -match $vCenter | Where-Object Cluster -match $RootCluster | Where-Object Model -match $RootModel | Where-Object PhysicalLocation -match $PhysicalLocation | Select-Object -ExpandProperty HostName

                                #id,refs,type,name,model,version,labeltype
                                #7,"10,11",PhysicalLocation,Ost,"","",label2
                                "$($vcNo)$($ClusterNo)$($ModelNo)$($PhysicalLocationNo),$($vcNo)$($ClusterNo)$($ModelNo),PhysicalLocation,$($PhysicalLocation),"""","""",label2" | Add-Content $OutFile -Encoding utf8

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

                                    #id,refs,type,name,model,version,labeltype
                                    #10,"",ESXiHost,"ESXi7912","ProLiant DL380 Gen10","6.7",label3
                                    "$($vcNo)$($ClusterNo)$($ModelNo)$($PhysicalLocationNo)$($HostNameNo),$($vcNo)$($ClusterNo)$($ModelNo)$($PhysicalLocationNo),ESXiHost,""$($prefix) $($ESXiHost)"",$($RootModel),$($HostObject.Version),label3" | Add-Content $OutFile -Encoding utf8
                                    #"VC$($vcNo)C$($ClusterNo)M$($ModelNo)_$($PhysicalLocation) : $($prefix) $($ESXiHost), ESXi $($HostObject.Version), $($RootModel)" | Add-Content $OutFile -Encoding utf8
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