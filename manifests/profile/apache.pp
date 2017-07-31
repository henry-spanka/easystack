# Setup Apache
class easystack::profile::apache (
    String $servername = $::fqdn,
) {
    # make sure the parameters are initialized
    include ::easystack

    # Setup apache
    class { 'apache':
        default_vhost  => false,
        servername     => $servername,
        service_manage => false,
    }

    service { 'httpd':
        ensure  => undef,
        name    => 'httpd',
        enable  => false,
        stop    => 'echo 0',
        start   => 'echo 0',
        restart => 'echo 0',
    }

}
