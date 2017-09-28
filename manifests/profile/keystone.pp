# Setup Keystone Service
class easystack::profile::keystone (
    String $listen_ip       = ip_for_network($::easystack::config::management_network),
    String $vip             = $::easystack::config::controller_vip,
    String $admin_token     = $::easystack::config::keystone_admin_token,
    String $db_password     = $::easystack::config::database_keystone_password,
    Boolean $sync_db        = false,
    Hash $fernet_keys       = $::easystack::config::keystone_fernet_keys,
    Hash $credential_keys   = $::easystack::config::keystone_credential_keys,
    Array $controller_nodes = $::easystack::config::controller_nodes,
) {
    # make sure the parameters are initialized
    include ::easystack

    include apache

    class { 'keystone::wsgi::apache':
        servername => $::fqdn,
        ssl        => false,
        bind_host  => $listen_ip
    }

    selinux::port { 'allow-keystone-httpd-5000':
        seltype  => 'http_port_t',
        port     => 5000,
        protocol => 'tcp',
        before   => Anchor['easystack::openstack::service_1::begin']
    }
    selinux::port { 'allow-keystone-httpd-35357':
        seltype  => 'http_port_t',
        port     => 35357,
        protocol => 'tcp',
        before   => Anchor['easystack::openstack::service_1::begin']
    }
    selinux::boolean { 'httpd_can_network_connect_db':
        ensure => 'on',
        before => Anchor['easystack::openstack::service_1::begin'],
    }

    include ::firewalld

    firewalld_port { 'Allow keystone public and internal endpoint on port 5000 tcp':
      ensure   => present,
      zone     => 'internal',
      port     => 5000,
      protocol => 'tcp',
      tag      => 'keystone-firewall',
    }

    firewalld_port { 'Allow keystone admin endpoint on port 35357 tcp':
      ensure   => present,
      zone     => 'internal',
      port     => 35357,
      protocol => 'tcp',
      tag      => 'keystone-firewall',
    }

    $controller_nodes_ip = $controller_nodes.map |Hash $params| {
        $params[ip]
    }

    class { 'keystone':
        catalog_type            => 'sql',
        admin_token             => $admin_token,
        database_connection     => "mysql+pymysql://keystone:${db_password}@${vip}/keystone",
        token_provider          => 'fernet',
        service_name            => 'httpd',
        public_bind_host        => $listen_ip,
        admin_bind_host         => $listen_ip,
        public_endpoint         => "http://${vip}:5000",
        admin_endpoint          => "http://${vip}:35357",
        sync_db                 => $sync_db,
        enable_fernet_setup     => true,
        fernet_keys             => $fernet_keys,
        enable_credential_setup => true,
        credential_keys         => $credential_keys,
        cache_enabled           => true,
        cache_backend           => 'oslo_cache.memcache_pool',
        memcache_servers        => $controller_nodes_ip,
    }

    Anchor['easystack::openstack::install_1::begin']
    -> Anchor['keystone::install::begin']
    -> Anchor['keystone::install::end']
    -> Anchor['easystack::openstack::install_1::end']

    Anchor['easystack::openstack::config_1::begin']
    -> Anchor['keystone::config::begin']
    -> Anchor['keystone::config::end']
    -> Anchor['easystack::openstack::config_1::end']

    Anchor['easystack::openstack::dbsync_1::begin']
    -> Anchor['keystone::db::begin']
    -> Anchor['keystone::db::end']
    -> Anchor['keystone::dbsync::begin']
    -> Anchor['keystone::dbsync::end']
    -> Anchor['easystack::openstack::dbsync_1::end']

    Anchor['easystack::openstack::service_1::begin']
    -> Anchor['keystone::service::begin']
    -> Anchor['keystone::service::end']
    -> Anchor['easystack::openstack::service_1::end']

    Keystone_domain<||>
    -> Anchor['easystack::openstack::service_1::end']
    Keystone_endpoint<||>
    -> Anchor['easystack::openstack::service_1::end']
    Keystone_role<||>
    -> Anchor['easystack::openstack::service_1::end']
    Keystone_service<||>
    -> Anchor['easystack::openstack::service_1::end']
    Keystone_tenant<||>
    -> Anchor['easystack::openstack::service_1::end']
    Keystone_user<||>
    -> Anchor['easystack::openstack::service_1::end']
    Keystone_user_role<||>
    -> Anchor['easystack::openstack::service_1::end']

    Firewalld_port <|tag == 'keystone-firewall'|>
    -> Anchor['easystack::openstack::service_1::begin']

}
