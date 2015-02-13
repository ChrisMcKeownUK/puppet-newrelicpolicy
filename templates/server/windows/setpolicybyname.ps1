function GetAlertPolicyFromName
{
  # Takes the name of an Alerting Policy and returns the JSON for the alert policy if the name matches exactly one policy.
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

    {$_ -eq 1} { Write-Host "Matching policy found"; 
                 return (Invoke-RestMethod -Uri "https://api.newrelic.com/v2/alert_policies/$($response.alert_policies[0].id).json" -Headers @{"X-Api-Key" = $apiKey});
               }

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


function AddServerToPolicy
{
  # Takes the name of the New Relic policy that you would like the server to be added to,
  # the name of the server and the New Relic API key to use
  # Note that this function assumes that the test-inpolicy script has already been checked
  # to determine whether this script needs to be run or not. Therefore this script does not check
  # the current policy of the server.

  # This function returns True if the call to add the server to the policy returns with a 200 OK
  # and False otherwise.

  Param 
  (
    [string] $desiredPolicyName,
    [string] $serverName,
    [string] $apiKey
  )

  try
  {
    $policy = GetAlertPolicyFromName -name $desiredPolicyName -apiKey $apiKey;

    if ($policy -eq $false) { return $false } 

    $server = GetServerObjectFromName -serverName $serverName -apiKey $apiKey;

    if ($server -eq $false) { return $false }
  }
  catch [System.Exception]
  {
      Write-Host "Exception occured calling New Relic API: $_";
      return $false;
  }

  # The call to .Invoke here gets the list of servers as a non-fixed length array
  $serverList = { $policy.alert_policy.links.servers }.Invoke();
  Write-Host "Current server list for Policy ID $($policy.Id): $serverList";

  $serverList.Add($server.Id);
  Write-Host "New server list: $serverList";

  # Insert the new list back into the JSON object
  $policy.alert_policy.links.servers = $serverList;

  $body = $policy | ConvertTo-Json -Depth 5
  try
  {
    $response =  Invoke-RestMethod -Uri "https://api.newrelic.com/v2/alert_policies/$($policy.alert_policy.id).json" -Method Put -Headers @{"X-Api-Key" = $apiKey; "Content-Type" = 'application/json'} -Body $body;
    return $true;
  }
  catch [System.Exception]
  {
      Write-Host "Exception occured calling New Relic API: $_";
      return $false;
  }
  # Should be unreachable, return false to signify failure.
  return $false;
}

$result = AddServerToPolicy -desiredPolicyName "<%= scope.lookupvar('newrelicpolicy::serverpolicyname') %>" -serverName $env:COMPUTERNAME -apiKey "<%= scope.lookupvar('newrelicpolicy::apikey') %>"

if ($result) { exit 0 } else { exit 1 }
