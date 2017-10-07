# Setup Nova API
class easystack::profile::nova::api (
    String $listen_ip     = ip_for_network($::easystack::config::management_network),
    Boolean $sync_db      = false,
    String $shared_secret = $::easystack::config::neutron_metadata_shared_secret
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::nova

    class { 'nova::api':
        enabled_apis                         => ['osapi_compute', 'metadata'],
        api_bind_address                     => $listen_ip,
        metadata_listen                      => $listen_ip,
        sync_db                              => $sync_db,
        sync_db_api                          => $sync_db,
        neutron_metadata_proxy_shared_secret => $shared_secret,
    }

    include ::firewalld

    firewalld_port { 'Allow nova compute api on port 8774 tcp - zone=internal':
        ensure   => present,
        zone     => 'internal',
        port     => 8774,
        protocol => 'tcp',
        tag      => 'nova-firewall',
        before   => Service['nova-api'],
    }

    firewalld_port { 'Allow nova compute api on port 8774 tcp - zone=public_mgmt':
        ensure   => present,
        zone     => 'public_mgmt',
        port     => 8774,
        protocol => 'tcp',
        tag      => 'nova-firewall',
        before   => Service['nova-api'],
    }

    firewalld_port { 'Allow nova metadata api on port 8775 tcp':
        ensure   => present,
        zone     => 'internal',
        port     => 8775,
        protocol => 'tcp',
        tag      => 'nova-firewall',
        before   => Service['nova-api'],
    }

}
