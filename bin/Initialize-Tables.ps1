$Data    = $($PSScriptRoot).Replace('bin','data')
$Upload  = Join-Path -Path $($PSScriptRoot).Replace('bin','pode') -ChildPath upload

$Files = @(
    'classic_ESXiHosts'
    'cloud_ESXiHosts'
    'classic_summary'
    'cloud_summary'
    'cloud_Datastores'
    'classic_Datastores'
    # 'cloud_Networks'
)
foreach($file in $Files){
    $Source  = Join-Path -Path $Data -ChildPath "$file.csv"
    $Target  = Join-Path -Path $Upload -ChildPath "$file.csv"
    Copy-Item -Path $Source -Destination $Target -Force -PassThru
    Start-Sleep -Seconds 3
}
