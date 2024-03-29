# Setup Glance API
class easystack::profile::glance::api (
    String $listen_ip      = ip_for_network($::easystack::config::management_network),
    String $vip            = $::easystack::config::controller_vip,
    String $db_password    = $::easystack::config::database_glance_password,
    String $default_store  = 'file',
    Array $store_backends  = ['file', 'http'],
    Boolean $sync_db       = false,
    String $admin_endpoint = $::easystack::config::admin_endpoint,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::glance

    class { '::glance::api':
        database_connection          => "mysql+pymysql://glance:${db_password}@${vip}/glance",
        auth_strategy                => 'keystone',
        show_image_direct_url        => true,
        default_store                => $default_store,
        multi_store                  => true,
        bind_host                    => $listen_ip,
        enable_v1_api                => false,
        enable_v2_api                => true,
        sync_db                      => $sync_db,
        pipeline                     => 'keystone',
        stores                       => $store_backends,
        conversion_format            => 'raw',
        show_multiple_locations      => true,
        registry_host                => $admin_endpoint,
        registry_port                => '9191',
        registry_client_protocol     => 'https',
        enable_proxy_headers_parsing => true,
    }

    include ::firewalld

    firewalld_port { 'Allow glance api on port 9292 tcp - zone=internal':
        ensure   => present,
        zone     => 'internal',
        port     => 9292,
        protocol => 'tcp',
        tag      => 'glance-firewall',
    }

    firewalld_port { 'Allow glance api on port 9292 tcp - zone=public_mgmt':
        ensure   => present,
        zone     => 'public_mgmt',
        port     => 9292,
        protocol => 'tcp',
        tag      => 'glance-firewall',
    }

}
