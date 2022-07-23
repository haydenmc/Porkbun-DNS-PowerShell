<#
    A PowerShell script to update a DNS record on Porkbun
    Using an IP address from a network adapter with a given alias
#>

param(
    # The alias for the interface to get the IP address from
    [Parameter(Mandatory = $true)]
    [string]
    $InterfaceAlias,
    # The address family to retrieve (IPv4, IPv6)
    [Parameter()]
    [ValidateSet("IPv4", "IPv6")]
    [string]
    $AddressFamily = "IPv6",
    # Porkbun API key
    [Parameter(Mandatory = $true)]
    [string]
    $ApiKey,
    # Porkbun API secret
    [Parameter(Mandatory = $true)]
    [string]
    $ApiSecret,
    # Hostname to update records for
    [Parameter(Mandatory = $true)]
    [string]
    $Hostname,
    # Subdomain to use for the record
    [Parameter(Mandatory = $true)]
    [string]
    $Subdomain,
    # Record type to update
    [Parameter()]
    [string]
    $RecordType = "AAAA",
    # TTL value
    [Parameter()]
    [int]
    $TTL = 600
)

# Constants
$ApiUri = "https://porkbun.com/api/json/v3"

# Fetch the IP from the given adapter
$IpAddress = Get-NetIPAddress |`
    Where-Object InterfaceAlias -ieq $InterfaceAlias |`
    Where-Object AddressFamily -ieq $AddressFamily |`
    Where-Object AddressState -ieq "Preferred" |`
    Where-Object PrefixOrigin -ine "WellKnown" |` # Filter reserved addresses
    Select-Object -Index 0 |`
    Select-Object -ExpandProperty "IPAddress"

# Construct body
$payload = @{
    "secretapikey" = $ApiSecret;
    "apikey" = $ApiKey;
}

Write-Host -ForegroundColor Cyan `
    "Checking for existing '$RecordType' record on '$Subdomain.$Hostname'..."
$existingRecordsRequest = Invoke-WebRequest -Method "POST"`
    -Uri "$ApiUri/dns/retrieveByNameType/$Hostname/$RecordType/$Subdomain"`
    -ContentType "application/json"`
    -Body (ConvertTo-Json $payload)
$existingRecordsContent = $existingRecordsRequest.Content | ConvertFrom-Json
if ($existingRecordsContent.records.Count -le 0)
{
    Write-Host -ForegroundColor Cyan `
        "Creating new '$RecordType' on '$Subdomain.$Hostname' to '$IpAddress' ..."
    $payload = @{
        "secretapikey" = $ApiSecret;
        "apikey" = $ApiKey;
        "name" = $Subdomain;
        "type" = $RecordType;
        "content" = $IpAddress;
        "ttl" = $TTL;
    }
    $newRecordRequest = Invoke-WebRequest -Method "POST"`
        -Uri "$ApiUri/dns/create/$Hostname"`
        -ContentType "application/json"`
        -Body (ConvertTo-Json $payload)
    Write-Host -ForegroundColor Green `
        "$($newRecordRequest.StatusCode) $($newRecordRequest.StatusMessage)"
}
else
{
    $recordContent = $existingRecordsContent.records[0].content
    if ($recordContent -ieq $IpAddress)
    {
        Write-Host -ForegroundColor Green "Existing record is already set to '$IpAddress'!"
    }
    else
    {
        $recordId = $existingRecordsContent.records[0].id
        Write-Host -ForegroundColor Cyan "Updating existing record id $recordId to '$IpAddress' ..."
        $payload = @{
            "secretapikey" = $ApiSecret;
            "apikey" = $ApiKey;
            "name" = $Subdomain;
            "type" = $RecordType;
            "content" = $IpAddress;
            "ttl" = "$TTL";
        }
        $updateRecordRequest = Invoke-WebRequest -Method "POST"`
            -Uri "$ApiUri/dns/edit/$Hostname/$recordId"`
            -ContentType "application/json"`
            -Body (ConvertTo-Json $payload)
        Write-Host -ForegroundColor Green `
            "$($updateRecordRequest.StatusCode) $($updateRecordRequest.StatusMessage)"
    }
}