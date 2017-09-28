# Setup Keystone API Resource
class easystack::profile::corosync::keystone {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync
    include ::easystack::profile::corosync::deps::keystone

    include ::easystack::profile::corosync::httpd

}
