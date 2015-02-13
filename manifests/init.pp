class newrelicpolicy (
  $manage_serverpolicy = $newrelicpolicy::params::manage_serverpolicy,
  $serverpolicyname    = $newrelicpolicy::params::serverpolicyname,
  $serverpolicyid      = $newrelicpolicy::params::serverpolicyid,
  $apikey              = $newrelicpolicy::params::apikey,
) inherits newrelicpolicy::params {

  if $manage_serverpolicy {
  
    if !$apikey or (!$serverpolicyid and !$serverpolicyname) {
      fail("Param manage_serverpolicy was set to true but no API key, policy name or policy ID was specified.")
    }
    
    if $serverpolicyid {
      class{'newrelicpolicy::server::policy':
        setmethod = 'id',
      }
    }
    elsif $serverpolicyname {
      class{'newrelicpolicy::server::policy':
        setmethod = 'name'
      }
    }
    
  }
  
}
