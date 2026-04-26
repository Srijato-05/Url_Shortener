param (
    [string]$Domain = ""
)

# URL Shortener Automated Startup Script
# This script automatically discovers your LAN IP and starts the Docker services
# ensuring that shortened URLs are reachable by everyone on your network.

# 1. Discover Primary IPv4 Address (Prioritizing 192.168.x.x range)
$addresses = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
    $_.InterfaceAlias -notmatch 'Loopback|VirtualBox|VMware' -and 
    $_.IPAddress -notmatch '^169\.254\.|^192\.168\.56\.' 
}

$ip = ($addresses | Where-Object { $_.IPAddress -like '192.168.*' } | Select-Object -First 1).IPAddress
if (-not $ip) {
    $ip = ($addresses | Select-Object -First 1).IPAddress
}

if (-not $ip) {
    Write-Output "Warning: Could not automatically detect primary LAN IP. Falling back to localhost."
    $ip = "localhost"
}

if ($Domain) {
    # 1.1 Automated Branding Registration (Requires Admin)
    # Note: For cross-device support (phones/tablets), use 'naiyo24.local' and set PC name to 'naiyo24'
    try {
        $hostFile = "$env:windir\System32\drivers\etc\hosts"
        $mapping = "127.0.0.1  $Domain"
        if (!(Select-String -Path $hostFile -Pattern $Domain -Quiet)) {
            Write-Output "Attempting to register branded domain locally..."
            Add-Content -Path $hostFile -Value "`n$mapping" -ErrorAction Stop
            Write-Output "Successfully registered $Domain in HOSTS file."
        }
    } catch {
        Write-Output "Note: Branded resolution (http://$Domain) requires a one-time HOSTS entry."
        Write-Output "To enable it automatically, run this script as Administrator."
    }

    $ip = $Domain
    $apiBase = "http://$Domain"
} else {
    $apiBase = "http://$($ip):8000"
}

Write-Output "---"
Write-Output "Primary Identity: $ip"
Write-Output "Base URL Configured: $apiBase"
Write-Output "---"

# 2. Inject into Environment and Start Docker
$env:API_BASE_URL = $apiBase
docker compose up --build -d

Write-Output ""
Write-Output "Deployment Successful!"
if ($Domain) {
    Write-Output "Branded Identity Active: $Domain"
    Write-Output "Branded Links: http://$($Domain)/[alias]"
}
Write-Output "Access the Dashboard at: http://$($ip)"
Write-Output "Access the API (Swagger) at: http://$($ip)/api/docs"
Write-Output ""
