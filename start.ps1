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
    $dashboardUrl = "http://$Domain"
} else {
    $apiBase = "http://$($ip):8081"
    $dashboardUrl = "http://$($ip):8081"
}

Write-Output "---"
Write-Output "Primary Identity: $ip"
Write-Output "Base URL Configured: $apiBase"
Write-Output "---"

# 2. Inject into Environment, Persist in .env, and Start Docker
$env:API_BASE_URL = $apiBase

$envFile = Join-Path $PSScriptRoot ".env"
if (-not (Test-Path $envFile)) {
    Write-Output "Creating default .env file..."
    $defaultEnv = @(
        "# Environment variables for Docker Compose",
        "# Using Port 8081 to avoid potential conflicts with Port 80",
        "API_BASE_URL=http://localhost:8081",
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

docker compose up --build -d
docker compose restart nginx

Write-Output ""
Write-Output "Deployment Successful!"
if ($Domain) {
    Write-Output "Branded Identity Active: $Domain"
    Write-Output "Branded Links: http://$($Domain)/[alias]"
}
Write-Output "Access the Dashboard at: $dashboardUrl"
Write-Output "Access the API (Swagger) at: $dashboardUrl/api/docs"
Write-Output ""
