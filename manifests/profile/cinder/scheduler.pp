# Setup Cinder Scheduler
class easystack::profile::cinder::scheduler {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::cinder

    class { 'cinder::scheduler':
        enabled        => true,
        manage_service => true,
    }

}
