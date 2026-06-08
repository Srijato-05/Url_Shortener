param (
    [string]$Domain = ""
)

# URL Shortener Automated Run Script (Fast Launch)
# This script automatically discovers your LAN IP, sets up the environment variables,
# and starts the existing Docker containers instantly without rebuilding them.

# 1. Discover Primary IPv4 Address (Prioritizing active internet-facing network adapter)
$activeRoute = Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Where-Object { $_.NextHop -ne '0.0.0.0' } | Select-Object -First 1
$ip = $null

if ($activeRoute) {
    $ip = (Get-NetIPAddress -InterfaceIndex $activeRoute.InterfaceIndex -AddressFamily IPv4 | Select-Object -First 1).IPAddress
}

if (-not $ip) {
    $addresses = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
        $_.InterfaceAlias -notmatch 'Loopback|VirtualBox|VMware|vEthernet|WSL|Docker|Hyper-V|Virtual|Pseudo|Host-Only|Tailscale|TAP' -and 
        $_.IPAddress -notmatch '^169\.254\.' 
    }
    $ip = ($addresses | Where-Object { 
        $_.IPAddress -like '192.168.*' -or 
        $_.IPAddress -like '10.*' -or 
        $_.IPAddress -match '^172\.(1[6-9]|2[0-9]|3[0-1])\.' 
    } | Select-Object -First 1).IPAddress
    
    if (-not $ip) {
        $ip = ($addresses | Select-Object -First 1).IPAddress
    }
}

if (-not $ip) {
    Write-Output "Warning: Could not automatically detect primary LAN IP. Falling back to localhost."
    $ip = "localhost"
}

if ($Domain) {
    try {
        $hostFile = "$env:windir\System32\drivers\etc\hosts"
        $mapping = "127.0.0.1  $Domain"
        if (!(Select-String -Path $hostFile -Pattern $Domain -Quiet)) {
            Write-Output "Attempting to register branded domain locally..."
            Add-Content -Path $hostFile -Value "`n$mapping" -ErrorAction Stop
            Write-Output "Successfully registered $Domain in HOSTS file."
        }
    } catch {
        Write-Output "Note: Branded resolution (http://$($Domain)) requires a one-time HOSTS entry."
        Write-Output "To enable it automatically, run this script as Administrator."
    }

    $ip = $Domain
    $apiBase = "http://$($Domain):8000"
    $dashboardUrl = "http://$($Domain):8080"
} else {
    $apiBase = "http://$($ip):8000"
    $dashboardUrl = "http://$($ip):8080"
}

Write-Output "---"
Write-Output "Primary Identity: $ip"
Write-Output "Base URL Configured: $apiBase"
Write-Output "---"

# 2. Inject into Environment, Persist in .env, and Start Docker Compose Fast
$env:API_BASE_URL = $apiBase

$envFile = Join-Path $PSScriptRoot ".env"
if (-not (Test-Path $envFile)) {
    Write-Output "Creating default .env file..."
    $defaultEnv = @(
        "# Environment variables for Docker Compose",
        "API_BASE_URL=http://localhost:8000",
        "DATABASE_URL=postgresql://user:password@postgres/url_db",
        "REDIS_URL=redis://redis:6379/0",
        "ALLOWED_ORIGINS=*",
        "PYTHONPATH=./url_shortener_backend"
    )
    $defaultEnv | Set-Content $envFile
}

$content = Get-Content $envFile
$newContent = @()
$found = $false
foreach ($line in $content) {
    if ($line -match '^#?\s*API_BASE_URL=') {
        $newContent += "API_BASE_URL=$apiBase"
        $found = $true
    } else {
        $newContent += $line
    }
}
if (-not $found) {
    $newContent += "API_BASE_URL=$apiBase"
}
$newContent | Set-Content $envFile

# Start existing services without rebuild flag
docker compose up -d

Write-Output ""
Write-Output "Launch Successful (Fast Start)!"
if ($Domain) {
    Write-Output "Branded Identity Active: $Domain"
    Write-Output "Branded Links: http://$($Domain):8000/[alias]"
}
Write-Output "Access the Dashboard at: $dashboardUrl"
Write-Output "Access the API (Swagger) at: $apiBase/docs"
Write-Output ""
