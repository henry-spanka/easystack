# Setup Apache
class easystack::profile::apache (
    String $servername = $::fqdn,
) {
    # make sure the parameters are initialized
    include ::easystack

    # Setup apache
    class { 'apache':
        default_vhost => false,
        servername    => $servername,
    }

}
