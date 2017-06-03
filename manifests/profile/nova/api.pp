# Setup Nova API
class easystack::profile::nova::api (
    String $listen_ip = ip_for_network($::easystack::config::management_network),
    Boolean $sync_db  = false,
) {
    # make sure the parameters are initialized
    include ::easystack

    include apache

    include ::easystack::profile::nova

    class { 'nova::api':
        enabled_apis     => ['osapi_compute', 'metadata'],
        api_bind_address => $listen_ip,
        metadata_listen  => $listen_ip,
        service_name     => 'httpd',
        sync_db          => $sync_db,
        sync_db_api      => $sync_db,
    }

    class { '::nova::wsgi::apache':
        ssl        => false,
        bind_host  => $listen_ip,
        servername => $::fqdn,
    }

    selinux::port { 'allow-nova-api-httpd-8774':
        seltype  => 'http_port_t',
        port     => 8774,
        protocol => 'tcp',
        notify   => Class['apache::service'],
        require  => Class['apache'],
    }

    include ::firewalld

    firewalld_port { 'Allow nova compute api on port 8774 tcp':
        ensure   => present,
        zone     => 'public',
        port     => 8774,
        protocol => 'tcp',
        tag      => 'nova-firewall',
        before   => Service['httpd'],
    }

    firewalld_port { 'Allow nova metadata api on port 8775 tcp':
        ensure   => present,
        zone     => 'public',
        port     => 8775,
        protocol => 'tcp',
        tag      => 'nova-firewall',
        before   => Service['httpd'],
    }

}
