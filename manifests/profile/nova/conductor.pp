# Setup Nova Conductor
class easystack::profile::nova::conductor {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::nova

    class { 'nova::conductor': }

}
