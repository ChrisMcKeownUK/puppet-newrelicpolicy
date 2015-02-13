class newrelicpolicy::server::policy (
  $setmethod,
{
  
  validate_re($setmethod, ['id', 'name'])
  
  case $setmethod {
    'id': {
      fail("Setting the policy by ID is not yet supported")
    }
    
    'name': {
      exec { 'checkandsetpolicybyname':
        command   => template('newrelicpolicy/server/windows/setpolicybyname.ps1'),
        unless    => template('newrelicpolicy/server/windows/checkpolicybyname.ps1'),
        provider  => powershell,
      }
    }
 
}