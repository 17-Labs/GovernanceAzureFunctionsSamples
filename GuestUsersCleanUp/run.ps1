using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}

$guestsWithNoAccess = Get-GuestsWithNoAccess
$guestsWithNoAccess | ForEach-Object { $_.userPrincipalName }
foreach ($guest in $guestsWithNoAccess) {
    Remove-GuestUser -userId $guest.id
}

if ($name) {
    $body = "OK"
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = "OK"
})

function Get-GraphToken {
    $appSettings = Get-AzureAppSettings
    $tenantId = $appSettings.TenantId
    $clientId = $appSettings.AppId
    $clientSecret = $appSettings.ClientSecret
    
    $body = @{
        Grant_Type    = "client_credentials"
        Scope         = "https://graph.microsoft.com/.default"
        Client_Id     = $clientId
        Client_Secret = $clientSecret
    }

    $tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Method Post -ContentType "application/x-www-form-urlencoded" -Body $body
    return $tokenResponse.access_token
}

# Function to get all guest users from Microsoft Graph
function Get-GuestUsers {
    $token = Get-GraphToken
    $uri = "https://graph.microsoft.com/v1.0/users?`$filter=userType eq 'Guest'"
    $headers = @{
        Authorization = "Bearer $token"
    }

    $guestUsers = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    return $guestUsers.value
}

# Function to get the last sign-in info of a user
function Get-LastSignInDate {
    param ($userId)

    $token = Get-GraphToken
    $uri = "https://graph.microsoft.com/beta/users/$userId/authentication/signInActivity"
    $headers = @{
        Authorization = "Bearer $token"
    }

    try {
        $signInData = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
        return $signInData.lastSignInDateTime
    } catch {
        # If no sign-in data available
        return $null
    }
}

# Function to filter guest users with no access in the last 90 days
function Get-GuestsWithNoAccess {
    $guestUsers = Get-GuestUsers
    $ninetyDaysAgo = (Get-Date).AddDays(-90)
    $inactiveGuests = @()

    foreach ($user in $guestUsers) {
        $lastSignIn = Get-LastSignInDate -userId $user.id

        if ($lastSignIn -eq $null -or ([DateTime]$lastSignIn -lt $ninetyDaysAgo)) {
            $inactiveGuests += $user
        }
    }

    return $inactiveGuests
}

# Function to remove a guest user from Azure AD
function Remove-GuestUser {
    param ($userId)

    $token = Get-GraphToken
    $uri = "https://graph.microsoft.com/v1.0/users/$userId"
    $headers = @{
        Authorization = "Bearer $token"
    }

    try {
        Invoke-RestMethod -Uri $uri -Headers $headers -Method Delete
        Write-Host "Successfully removed user with ID: $userId"
    } catch {
        Write-Host "Failed to remove user with ID: $userId"
    }
}

# Function to retrieve TenantId, AppId, and ClientSecret from environment variables
function Get-AzureAppSettings {
    $tenantId = $env:TenantId
    $appId = $env:AppId
    $clientSecret = $env:ClientSecret

    return @{
        TenantId = $tenantId
        AppId = $appId
        ClientSecret = $clientSecret
    }
}