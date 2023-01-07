Start-PodeServer {

    Write-Host "Press Ctrl. + C to terminate the Pode server" -ForegroundColor Yellow
    Add-PodeEndpoint -Address * -Port 5989 -Protocol Http

    Add-PodeRoute -Method Get -Path '/' -ScriptBlock {
        Write-PodeViewResponse -Path 'Pshtml-ESXiHost-Inventory'
    }

    if(($PSVersionTable.PSVersion.Major -lt 6) -or ($IsWindows)){
        # Start Browser
        Start-Process "microsoft-edge:http://localhost:5989/" -WindowStyle maximized
    }elseif($IsMacOS){
        # Start Browser
        Start-Process "http://localhost:5989/"
    }
    
}
