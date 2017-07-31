# Setup Glance API
class easystack::profile::glance::api (
    String $listen_ip     = ip_for_network($::easystack::config::management_network),
    String $vip           = $::easystack::config::controller_vip,
    String $db_password   = $::easystack::config::database_glance_password,
    String $default_store = 'rbd',
    Array $store_backends = ['rbd'],
    Boolean $sync_db      = false,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::glance

    class { '::glance::api':
        database_connection   => "mysql+pymysql://glance:${db_password}@${vip}/glance",
        auth_strategy         => 'keystone',
        show_image_direct_url => true,
        default_store         => $default_store,
        bind_host             => $listen_ip,
        enable_v1_api         => false,
        enable_v2_api         => true,
        sync_db               => $sync_db,
        pipeline              => 'keystone',
        stores                => $store_backends,
        conversion_format     => 'raw',
        manage_service        => false,
        enabled               => false,
    }

    include ::firewalld

    firewalld_port { 'Allow glance api on port 9292 tcp':
        ensure   => present,
        zone     => 'public',
        port     => 9292,
        protocol => 'tcp',
        tag      => 'glance-firewall',
        before   => Service['glance-api'],
    }

}
