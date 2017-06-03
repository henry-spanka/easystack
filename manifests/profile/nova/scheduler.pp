# Setup Nova Scheduler
class easystack::profile::nova::scheduler {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::nova

    class { 'nova::scheduler': }

}
