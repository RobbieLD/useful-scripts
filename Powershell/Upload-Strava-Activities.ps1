# Uploads an activity to strava with a given name and api key
# Client_Id: 80515
param(
    [string] $apiKey,
    [string] $device,
    [string] $clientId,
    [string] $clientSecret,
    [string] $configFileName
)

Function Get-AuthCode($id) {
    $authEndpoint = "https://www.strava.com/oauth/authorize?client_id=$id&redirect_uri=http://localhost&scope=activity%3Aread_all%2Cactivity%3Awrite&response_type=code"
    Write-Host "A browser will now open and ask you to authorize the app. Please paste the code=### value from the redirected url below"
    Start-Process $authEndpoint
    $authCode = Read-Host "Please enter auth code"
    return $authCode
}

Function Get-AuthToken($id, $secret, $code) {
    $endpoint = 'https://www.strava.com/oauth/token'
    $body = @{
        client_id = $id
        client_secret = $secret
        code = $code
        grant_type = 'authorization_code'
    }

    $response = Invoke-WebRequest -Method 'Post' -Uri $endpoint -Body $body
    return $response | ConvertFrom-Json
}

Function Get-RefreshAuthToken($id, $secret, $refresh) {
    $endpoint = 'https://www.strava.com/oauth/token'
    $body = @{
        client_id = $id
        client_secret = $secret
        grant_type = 'refresh_token'
        refresh_token = $refresh
    }

    $response = Invoke-WebRequest -Method 'Post' -Uri $endpoint -Body $body
    return $response | ConvertFrom-Json
}
Function Get-Authorisation($id, $secret, $code, $configPath) {

    # Read auth config if it exists
    if (Test-Path -Path $configPath -PathType Leaf) {
        $config = Get-Content -Path $configPath | ConvertFrom-Json

        # refresh token
        if ($config.expires_at -lt (New-TimeSpan -Start (Get-Date "01/01/1970") -End (Get-Date)).TotalSeconds) {
            $config = Get-RefreshAuthToken($id, $secret, $config.refresh_token)
            Out-File $configPath $config
            return $config.refresh_token
        } 
        else {
            return $config.access_token
        }
    }
    # No config exists so we need to auth the app
    else {
        $authorisationCode = Get-AuthCode($id)
        $config = Get-AuthToken($id, $secret, $authorisationCode)
        Out-File $configPath $config
        return $config.refresh_token
    }
}


# $url = "https://www.strava.com/api/v3/uploads"

# Write-Host " Searching for $device"

# $drive = (Get-Volume -FileSystemLabel $device).DriveLetter

# if (-Not $drive)
# {
#     Write-Error "No device found"
#     return
# }

# Write-Host "Device found with driver letter: $drive"

# $source = "$drive`:\GARMIN\ACTIVITY"

# Write-Host "Uploading from $source"


# $files = Get-ChildItem $source -Filter *.FIT

# foreach ($file in $files) {
    
#     Write-Host "Uplading $file"
     
#     $form = @{
#         data_type="fit"
#         file = Get-Item -Path $file
#     }

#     $headers = @{
#         Authorization = "Bearer $apiKey"
#     }

#     $result = Invoke-RestMethod -Method 'Post' -Uri $url -Form $form -Headers $headers

#     Write-Host $result
# }
