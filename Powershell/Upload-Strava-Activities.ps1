# Uploads an activity to strava with a given name and api key
[CmdletBinding()]
param(
    [Parameter()]
    [string]
    $Device,
    [Parameter()]
    [string]
    $ClientId,
    [Parameter()]
    [string]
    $ClientSecret,
    [Parameter()]
    [string]
    $ConfigFileName
)

Function Get-AuthCode {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $id
    )

    $authEndpoint = "https://www.strava.com/oauth/authorize?client_id=$id&redirect_uri=http://localhost&scope=activity%3Aread_all%2Cactivity%3Awrite&response_type=code"
    Write-Host "A browser will now open and ask you to authorize the app. Please paste the code=### value from the redirected url below"
    Start-Process $authEndpoint
    Read-Host "Please enter auth code" | Write-Output
    
}

Function Get-AuthToken {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $id,
        [Parameter()]
        [string]
        $secret,
        [Parameter()]
        [string]
        $code
    )
    $endpoint = 'https://www.strava.com/oauth/token'
    $body = @{
        client_id = $id
        client_secret = $secret
        code = $code
        grant_type = 'authorization_code'
    }

    Invoke-RestMethod -Method 'Post' -Uri $endpoint -Body $body | Write-Output
}

Function Get-RefreshAuthToken {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $id,
        [Parameter()]
        [string]
        $secret,
        [Parameter()]
        [string]
        $refresh
    )
    $endpoint = 'https://www.strava.com/oauth/token'
    $body = @{
        client_id = $id
        client_secret = $secret
        grant_type = 'refresh_token'
        refresh_token = $refresh
    }

    Invoke-RestMethod -Method 'Post' -Uri $endpoint -Body $body | Write-Output
}
Function Read-Config {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $id,
        [Parameter()]
        [string]
        $secret,
        [Parameter()]
        [string]
        $configPath
    )

    # Read auth config if it exists
    if (Test-Path -Path $configPath -PathType Leaf) {
        $config = Get-Content -Path $configPath | ConvertFrom-Json

        # refresh token
        if ($config.expires_at -lt (Get-Date -UFormat %s)) {
            $config = Get-RefreshAuthToken -id $id -secret $secret -refresh $config.refresh_token
            Out-File -FilePath $configPath -InputObject $config.Content
        }

        Write-Output $config.access_token
    }
    # No config exists so we need to auth the app
    else {
        $authorisationCode = Get-AuthCode -id $id
        $config = Get-AuthToken -id $id -secret $secret -code $authorisationCode
        Out-File -FilePath $configPath -InputObject $config
        Write-Output $config.access_token
    }
}
Function Get-UploadPath {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $deviceName
    )

    $drive = (Get-Volume -FileSystemLabel $deviceName).DriveLetter
    
    if (-Not $drive) {
        throw "No device found"
    }
    
    Write-Output "$drive`:\GARMIN\ACTIVITY"
}

Function Get-UploadStatus {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $id,
        [Parameter()]
        [string]
        $token
    )

    $url = "https://www.strava.com/api/v3/uploads/$id"
    $headers = @{
        Authorization = "Bearer $token"
    }

    Invoke-RestMethod -Method 'Get' -Uri $url -Headers $headers | Write-Output
}

Function Invoke-ActivityUpload {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $uploadPath,
        [Parameter()]
        [string]
        $token
    )

    $files = Get-ChildItem $uploadPath -Filter "*.FIT"
    $url = "https://www.strava.com/api/v3/uploads"
    $sleep = 5
    $isUploadDone = 0

    foreach($file in $files) {
      $form = @{
          data_type = "fit"
          file = Get-Item -Path $file
      }  

      $headers = @{
        Authorization = "Bearer $token"
      }

      Write-Host "Uploading $file"
      $uploadResponse = Invoke-RestMethod -Method 'Post' -Uri $url -Form $form -Headers $headers

      # wait for upload to be done with 5 second polling
      while (-not $isUploadDone) {
        Write-Host "Waiting for $sleep seconds to check the upload"
        Start-Sleep -Seconds $sleep
        $statusResponse = Get-UploadStatus -id $uploadResponse.id -token $token
        
        if ($statusResponse.status -eq "Your activity is ready.") {
            $isUploadDone = 1
            Write-Host "Upload completed successfully and the activity will not be deleted"
            Remove-Item -Path $file
        }
        elseif($statusResponse.error) {
            $isUploadDone = 1
            Write-Host "There was an error uploading your activity: $($statusResponse.error)"
        }
        else {
            Write-Host "File still processing..."
        }
      }
    }
}

$authToken = Read-Config -id $ClientId -secret $ClientSecret -configPath $ConfigFileName
$sourcePath = Get-UploadPath -deviceName $Device
Write-Host "Starting upload from $sourcePath"
Invoke-ActivityUpload -uploadPath $sourcePath -token $authToken
