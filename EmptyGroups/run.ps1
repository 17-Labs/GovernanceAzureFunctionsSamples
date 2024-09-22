# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

Wait-Debugger

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# access to Graph API with appid, secret and tenantid
$tenantId = "your-tenant-id"
$appId = "
$secret = "

$resource = "https://graph.microsoft.com"
$tokenBody = @{
    grant_type    = "client_credentials"
    client_id     = $appId
    client_secret = $secret
    resource      = $resource
}

$tokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/token" -Body $tokenBody

$token = $tokenResponse.access_token

# get the list of all empty groups in the tenant excluding the default groups
$groups = Invoke-RestMethod -Method Get -Uri "https://graph.microsoft.com/v1.0/groups?\$filter=groupTypes/any(c:c+eq+'Unified') and securityEnabled eq false" -Headers @{
    Authorization = "Bearer $token"
}

# iterate over the groups and save them in another array
$emptyGroups = @()
foreach ($group in $groups.value) {
    $members = Invoke-RestMethod -Method Get -Uri "https://graph.microsoft.com/v1.0/groups/$($group.id)/members" -Headers @{
        Authorization = "Bearer $token"
    }
    if ($members.value.Count -eq 0) {
        $emptyGroups += $group
    }
}

# iterate over the empty groups and delete them
foreach ($emptyGroup in $emptyGroups) {
    Invoke-RestMethod -Method Delete -Uri "https://graph.microsoft.com/v1.0/groups/$($emptyGroup.id)" -Headers @{
        Authorization = "Bearer $token"
    }
}

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"
