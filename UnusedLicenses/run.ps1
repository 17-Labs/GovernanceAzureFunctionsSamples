# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Function to get an access token from Azure AD (Client Credentials Flow)
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

# Function to get all licensed users in the tenant
function Get-LicensedUsers {
    $token = Get-GraphToken
    $uri = "https://graph.microsoft.com/v1.0/users?`$filter=assignedLicenses/any()"
    $headers = @{
        Authorization = "Bearer $token"
    }

    $licensedUsers = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    return $licensedUsers.value
}

# Function to get M365 license details for a specific user
function Get-UserLicenses {
    param ($userId)

    $token = Get-GraphToken
    $uri = "https://graph.microsoft.com/v1.0/users/$userId/licenseDetails"
    $headers = @{
        Authorization = "Bearer $token"
    }

    $licenseDetails = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    return $licenseDetails.value
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
        return $null  # No sign-in data available
    }
}

# Function to remove unused licenses for a user
function Remove-UserLicenses {
    param ($userId, $licenseIds)

    $token = Get-GraphToken
    $uri = "https://graph.microsoft.com/v1.0/users/$userId/assignLicense"
    $headers = @{
        Authorization = "Bearer $token"
        ContentType   = "application/json"
    }

    # Request body to remove licenses
    $body = @{
        addLicenses    = @()
        removeLicenses = $licenseIds
    } | ConvertTo-Json

    try {
        Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $body
        Write-Host "Successfully removed licenses for user with ID: $userId"
    } catch {
        Write-Host "Failed to remove licenses for user with ID: $userId"
    }
}

# Function to get users with unused licenses (no sign-in in the last 90 days)
function Get-UsersWithUnusedLicenses {
    $licensedUsers = Get-LicensedUsers
    $ninetyDaysAgo = (Get-Date).AddDays(-90)
    $usersWithUnusedLicenses = @()

    foreach ($user in $licensedUsers) {
        $lastSignIn = Get-LastSignInDate -userId $user.id

        # If no sign-in in the last 90 days or no sign-in activity at all, consider as not using the license
        if ($lastSignIn -eq $null -or ([DateTime]$lastSignIn -lt $ninetyDaysAgo)) {
            # Retrieve license details for this user
            $licenses = Get-UserLicenses -userId $user.id
            $licenseIds = $licenses | ForEach-Object { $_.skuId }

            $userDetails = @{
                UserPrincipalName = $user.userPrincipalName
                DisplayName       = $user.displayName
                LastSignIn        = $lastSignIn
                LicenseIds        = $licenseIds
            }
            $usersWithUnusedLicenses += $userDetails
        }
    }

    return $usersWithUnusedLicenses
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

# Example of running the function to get users with unused M365 licenses and removing those licenses
$usersWithUnusedLicenses = Get-UsersWithUnusedLicenses

foreach ($user in $usersWithUnusedLicenses) {
    Write-Host "Removing licenses for user: $($user.UserPrincipalName)"
    Remove-UserLicenses -userId $user.UserPrincipalName -licenseIds $user.LicenseIds
}

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"
