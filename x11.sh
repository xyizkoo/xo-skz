# WinPanti
$url = "https://get.activated.win"

# Use Invoke-RestMethod to download the script content
try {
    $scriptContent = Invoke-RestMethod -Uri $url -UseBasicParsing
} catch {
    Write-Host "Failed to retrieve the script from $url"
    return
}

# Use Invoke-Expression to execute the downloaded script content
Invoke-Expression $scriptContent