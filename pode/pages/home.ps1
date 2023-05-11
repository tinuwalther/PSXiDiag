Set-PodeWebHomePage -NoTitle -Layouts @(

    New-PodeWebCard -Name 'Welcome to the PSXi Homepage!' -Content @(
        New-PodeWebImage -Source 'assets/img/PSXiPode.png' -Alignment Center -Height 80% -Width 80%
    )

)
