param (
    [string] $targetBranch
)
   
Function Get-GitUrl {
    $url = git remote get-url origin
  
    # Check for SSH url and convert to https
    if ($url -like "git@*") {
        $url = $url.Replace(':', '/')
        $url = "https://" + $url.SubString(4)
    }
  
    # Sometimes they end in .git
    if ($url -like "*.git") {
        $url = $url.SubString(0, $url.Length - 4)
    }
  
    return $url
}
  
Function Get-NewPrPath {
    param (
        [string]$url,
        [string]$source,
        [string]$target
    )
  
    if ($url.Contains("dev.azure.com")) {
        return "/pullrequestcreate?sourceRef=$source&targetRef=$target"
    }
    if ($url.Contains("bitbucket.org")) {
        return "/pull-requests/new?source=$source&dest=$target"
    }
  
    throw "Unknown pull request format"
}

Function Get-BranchExists {
    param (
        [string]$branch
    )

    git rev-parse --verify $branch 2>&1 | Out-Null

    return $LASTEXITCODE -eq 0
}

Function Get-TargetBranch {
    $branches = @("develop", "master")
    foreach ($branch in $branches) {
        if (Get-BranchExists $branch) {
            return $branch
        }
    }

    return "master"
}


If (-Not $targetBranch) {
    $targetBranch = Get-TargetBranch
}
  
$branch = git rev-parse --abbrev-ref HEAD
if ($LASTEXITCODE -ne 0) {
    Write-Error "Not a repository"
    return;
}
$branch = [System.Web.HTTPUtility]::UrlEncode($branch)
$gitUrl = Get-GitUrl
$url = $gitUrl + (Get-NewPrPath -url $gitUrl -source $branch -target $targetBranch)
  
Start-Process $url
