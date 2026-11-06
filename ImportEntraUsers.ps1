param(
    [string]$csvPath = "C:\Users\<INSERT INFORMATION>\Downloads\Entra Users.csv",
    [string]$tenantId = "<INSERT DATA>", # <INSERT DATA> Tenant
    [string]$logPath = "C:\Users\<INSERT INFORMATION>\Downloads\entra_import_log.txt"
)

# ============================================================================
# <INSERT DATA> ENTRA USER BULK IMPORT
# Imports users from CSV with specific passwords
# Derived display names from UPN if FirstName/LastName empty
# ============================================================================

function Import-EntraUsersFromCsv {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$CsvPath,
        
        [string]$TenantId,
        
        [string]$LogPath
    )
    
    # Validate CSV exists
    if (-not (Test-Path $CsvPath)) {
        Write-Host "❌ CSV file not found: $CsvPath" -ForegroundColor Red
        return
    }
    
    # Check if module is installed
    Write-Host "📦 Checking Microsoft.Graph modules..." -ForegroundColor Cyan
    $requiredModules = @("Microsoft.Graph.Users", "Microsoft.Graph.Identity.DirectoryManagement")
    
    foreach ($module in $requiredModules) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            Write-Host "⏳ Installing $module..." -ForegroundColor Yellow
            Install-Module -Name $module -Force -Scope CurrentUser | Out-Null
        }
    }
    
    # Connect to Microsoft Graph
    Write-Host "🔐 Connecting to Microsoft Graph..." -ForegroundColor Cyan
    try {
        if ($TenantId) {
            Connect-MgGraph -TenantId $TenantId -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All" -ErrorAction Stop | Out-Null
        } else {
            Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All" -ErrorAction Stop | Out-Null
        }
        Write-Host "✓ Connected to Microsoft Graph" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to connect to Microsoft Graph: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
    
    # Import CSV
    Write-Host "📖 Reading CSV file..." -ForegroundColor Cyan
    try {
        $users = Import-Csv -Path $CsvPath -ErrorAction Stop
        Write-Host "✓ Loaded $($users.Count) users" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to read CSV: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
    
    # Initialize tracking
    $results = @()
    $successCount = 0
    $failureCount = 0
    $skipCount = 0
    $startTime = Get-Date
    
    # Process each user
    Write-Host "`n🚀 Starting user import..." -ForegroundColor Cyan
    Write-Host "=" * 80
    
    foreach ($index, $user in $users.GetEnumerator()) {
        $userNum = $index + 1
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        try {
            # Validate UPN
            $upn = $user.UserPrincipalName.Trim()
            if ([string]::IsNullOrWhiteSpace($upn)) {
                Write-Host "⊘ [$userNum/$($users.Count)] Skipping: Empty UPN" -ForegroundColor Yellow
                $results += [PSCustomObject]@{
                    Timestamp = $timestamp
                    UserNum   = "$userNum/$($users.Count)"
                    UPN       = "EMPTY"
                    Status    = "SKIPPED"
                    Message   = "Empty UPN"
                }
                $skipCount++
                continue
            }
            
            # Derive display name if FirstName/LastName are empty
            $firstName = $user.FirstName.Trim()
            $lastName = $user.LastName.Trim()
            
            if ([string]::IsNullOrWhiteSpace($firstName) -and [string]::IsNullOrWhiteSpace($lastName)) {
                # Extract from UPN (e.g., "alpdisp1" -> "Alp Disp1" or "alpmob15" -> "Alp Mob15")
                $upnPrefix = $upn.Split('@')[0]
                # Insert space before capital letter if mixed case, otherwise use as-is
                $displayName = $upnPrefix
                if ($upnPrefix -match '([a-z]+)(\d+)') {
                    $displayName = "$($matches[1]) $($matches[2])"
                }
                $firstName = $displayName.Split(' ')[0]
                $lastName = if ($displayName.Split(' ').Count -gt 1) { $displayName.Split(' ')[1] } else { $displayName }
            }
            
            $displayName = "$firstName $lastName"
            
            # Check if user already exists
            $existingUser = $null
            try {
                $existingUser = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue
            } catch {
                # Continue if query fails, might be a permission issue
            }
            
            if ($existingUser) {
                Write-Host "⊘ [$userNum/$($users.Count)] $upn - Already exists" -ForegroundColor Yellow
                $results += [PSCustomObject]@{
                    Timestamp = $timestamp
                    UserNum   = "$userNum/$($users.Count)"
                    UPN       = $upn
                    Status    = "SKIPPED"
                    Message   = "User already exists"
                }
                $skipCount++
                continue
            }
            
            # Get password
            $password = $user.Password.Trim()
            if ([string]::IsNullOrWhiteSpace($password)) {
                Write-Host "⊘ [$userNum/$($users.Count)] $upn - No password provided" -ForegroundColor Yellow
                $results += [PSCustomObject]@{
                    Timestamp = $timestamp
                    UserNum   = "$userNum/$($users.Count)"
                    UPN       = $upn
                    Status    = "SKIPPED"
                    Message   = "No password provided"
                }
                $skipCount++
                continue
            }
            
            # Prepare user parameters
            $mailNickname = $upn.Split('@')[0]
            $userParams = @{
                UserPrincipalName = $upn
                DisplayName       = $displayName
                GivenName         = $firstName
                Surname           = $lastName
                MailNickname      = $mailNickname
                PasswordProfile   = @{
                    Password                      = $password
                    ForceChangePasswordNextSignIn = $true
                }
                AccountEnabled    = $true
            }
            
            # Create user
            $newUser = New-MgUser @userParams -ErrorAction Stop
            
            $successCount++
            Write-Host "✓ [$userNum/$($users.Count)] $upn - Created" -ForegroundColor Green
            
            $results += [PSCustomObject]@{
                Timestamp = $timestamp
                UserNum   = "$userNum/$($users.Count)"
                UPN       = $upn
                DisplayName = $displayName
                Status    = "SUCCESS"
                Message   = "User created"
            }
            
        } catch {
            $failureCount++
            $errorMsg = $_.Exception.Message
            Write-Host "❌ [$userNum/$($users.Count)] $upn - $errorMsg" -ForegroundColor Red
            
            $results += [PSCustomObject]@{
                Timestamp = $timestamp
                UserNum   = "$userNum/$($users.Count)"
                UPN       = $upn
                Status    = "FAILED"
                Message   = $errorMsg
            }
        }
    }
    
    # Export results to log
    Write-Host "`n" 
    Write-Host "=" * 80
    Write-Host "📝 Saving results to log..." -ForegroundColor Cyan
    
    try {
        $results | Export-Csv -Path $LogPath -NoTypeInformation -Encoding UTF8
        Write-Host "✓ Log saved to: $LogPath" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Could not save log file: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Summary
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    Write-Host "`n"
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║       IMPORT SUMMARY - <INSERT DATA>      ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host "Total Users:     $($users.Count)" -ForegroundColor White
    Write-Host "✓ Created:       $successCount" -ForegroundColor Green
    Write-Host "❌ Failed:        $failureCount" -ForegroundColor Red
    Write-Host "⊘ Skipped:       $skipCount" -ForegroundColor Yellow
    Write-Host "⏱️  Duration:     $($duration.ToString('mm\:ss'))" -ForegroundColor White
    Write-Host "📝 Log:          $LogPath" -ForegroundColor White
    Write-Host ""
    
    # Disconnect
    Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
}

# Run the import
Import-EntraUsersFromCsv -CsvPath $csvPath -TenantId $tenantId -LogPath $logPath
