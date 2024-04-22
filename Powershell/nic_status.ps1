Clear-Host
$timeDelay = 302
# Configure the network interfaces to monitor
$netInterface = "Local Area Connection", "Wi-Fi" # Retrieve names for your network interfaces via Get-NetAdapter | Select Name

$WShell = New-Object -com "Wscript.Shell"
while ($true) {
    $currentTime = Get-Date
    Write-Host `r # Write a blank line
    Write-Host "Current Time: $currentTime"
    Write-Host `r
    # Loop through each network interface and display the status with color green if up, red if down
    foreach ($nic in $netInterface) {
        $adapter = Get-NetAdapter -Name $nic | Select Name, Status, LinkSpeed
        if ($adapter.Status -eq "Up") {
            Write-host "Adapter Name: $($adapter.Name), Status: $($adapter.Status), Link Speed: $($adapter.LinkSpeed)" -ForegroundColor Green
        } else {
            Write-host "Adapter Name: $($adapter.Name), Status: $($adapter.Status)" -ForegroundColor Red
        }
    }
    Write-Host `r
    Write-Host "Automatically toggling Scroll Lock..."
    $WShell.sendkeys("{SCROLLLOCK}") # Toggle the Scroll Lock key https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.sendkeys?view=windowsdesktop-8.0
    Start-Sleep -Milliseconds 200
    $WShell.sendkeys("{SCROLLLOCK}")
    Write-Host "Waiting for $timeDelay to pass..." -ForegroundColor Yellow
    Start-Sleep -Seconds $timeDelay
}
