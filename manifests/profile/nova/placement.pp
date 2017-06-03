# Setup Nova Placement API
class easystack::profile::nova::placement (
    String $listen_ip          = ip_for_network($::easystack::config::management_network),
    String $vip                = $::easystack::config::controller_vip,
    String $placement_password = $::easystack::config::keystone_nova_placement_password,
    String $region             = $::easystack::config::keystone_region,
) {
    # make sure the parameters are initialized
    include ::easystack

    include apache

    include ::easystack::profile::nova

    class { 'nova::placement':
        os_region_name      => $region,
        project_domain_name => 'default',
        project_name        => 'services',
        auth_type           => 'password',
        auth_url            => "http://${vip}:35357/v3",
        username            => 'placement',
        password            => $placement_password,
    }

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
