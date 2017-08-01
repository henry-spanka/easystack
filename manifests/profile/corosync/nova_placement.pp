# Setup Nova Placement API Resource
class easystack::profile::corosync::nova_placement {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync

    include ::easystack::profile::corosync::httpd

    Class['::easystack::profile::nova::placement']
    -> Class['::easystack::profile::corosync::httpd']

}
