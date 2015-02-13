function GetAlertPolicyIdFromName
{
  # Takes the name of an Alerting Policy and returns the integer ID of the policy.
  # Returns False if one of the following is met:
  #  - The policy name matches no policies
  #  - The policy name matches multiple policies

  Param
  (
    [string] $name,
    [string] $apiKey
  )

  $response =  (Invoke-RestMethod -Uri "https://api.newrelic.com/v2/alert_policies.json" -Method Post -Headers @{"X-Api-Key" = $apiKey} -Body "filter[name]=$name");

  switch ($response.alert_policies.Count)
  {
    {$_ -eq 0} { Write-Host "No server policies found matching name $name"; return $false;                         }
    {$_ -gt 1} { Write-Host "Policy name $name matches multiple policies";  return $false;                         }
    {$_ -eq 1} { Write-Host "Matching policy found";                        return $response.alert_policies[0].id; }
    default    { Write-Host "Fall through";                                 return $false                          }
  }
}

function GetServerObjectFromName
{
  Param
  (
    [string] $serverName,
    [string] $apiKey
  )

  $response =  (Invoke-RestMethod -Uri "https://api.newrelic.com/v2/servers.json" -Method Post -Headers @{"X-Api-Key" = $apiKey} -Body "filter[name]=$serverName");

  switch ($response.servers.Count)
  {
    {$_ -eq 0} { Write-Host "Server name $serverName not registered with New Relic";      return $false;               }
    {$_ -gt 1} { Write-Host "Ambigous server name: '$serverName' matches multiple hosts"; return $false;               }
    {$_ -eq 1} { Write-Host "Matching server found";                                      return $response.servers[0]; }
    default    { Write-Host "Fall through";                                               return $false;               }
  }
}

function CheckIfPolicyChangeRequired
{
  # This function only returns true if a change is needed and is possible. That is to say that all of the following are met:
  # 1. The server name matches exactly one server in the New Relic account.
  # 2. The policy name matches exactly one policy in the New Relic account.
  # 3. The current policy of the server does not match the desired policy.
  #
  # If any of the above conditions are not met, or an exception is returned from the API, the function returns false.

  Param 
  (
    [string] $desiredPolicyName,
    [string] $serverName,
    [string] $apiKey
  )

  try
  {
    $policyId = GetAlertPolicyIdFromName -name $desiredPolicyName -apiKey $apiKey;

    if ($policyId -eq $false) { return $false } 

    $server = GetServerObjectFromName -serverName $serverName -apiKey $apiKey;

    if ($server -eq $false) { return $false }
  }
  catch [System.Exception]
  {
      Write-Host "Exception occured calling New Relic API: $_";
      return $false;
  }

  $currentPolicy = $server.links.alert_policy;
  Write-Host "Current alert policy ID for $serverName is $currentPolicy";
  Write-Host "Desired alert policy ID for $serverName is $policyId";

  return ($currentPolicy -ne $policyId);

}

$result = CheckIfPolicyChangeRequired -desiredPolicyName "<%= scope.lookupvar('newrelicpolicy::serverpolicyname') %>" -serverName $env:COMPUTERNAME -apiKey "<%= scope.lookupvar('newrelicpolicy::apikey') %>"

if ($result) { exit 1 } else { exit 0 }
