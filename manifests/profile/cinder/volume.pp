# Setup Cinder Volume
class easystack::profile::cinder::volume {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::cinder

    class { '::cinder::volume': }

}
