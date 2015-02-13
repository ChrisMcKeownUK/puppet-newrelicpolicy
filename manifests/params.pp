class newrelicpolicy::params {

  case $::osfamily {
    'windows': {
      $manage_serverpolicy = undef,
      $serverpolicyname    = undef,
      $serverpolicyid      = undef,
      $apikey              = undef,
    }
    
    default: {
      fail("The ${module_name} module is not supported on an ${::osfamily} based system.")
    }
  }
  
}