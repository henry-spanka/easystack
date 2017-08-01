# Setup Nova Placement API
class easystack::profile::nova::placement_api (
    String $listen_ip = ip_for_network($::easystack::config::management_network),
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::nova

    include ::easystack::profile::nova::placement

    include apache

    class { 'nova::wsgi::apache_placement':
        servername => $::fqdn,
        api_port   => 8778,
        ssl        => false,
        bind_host  => $listen_ip,
    }

    selinux::port { 'allow-nova-placement-api-httpd-8778':
        seltype  => 'http_port_t',
        port     => 8778,
        protocol => 'tcp',
        notify   => Class['apache::service'],
        require  => Class['apache'],
    }

    include ::firewalld

    firewalld_port { 'Allow nova placement api on port 8778 tcp':
        ensure   => present,
        zone     => 'public',
        port     => 8778,
        protocol => 'tcp',
        tag      => 'nova-firewall',
        before   => Service['httpd'],
    }

}
