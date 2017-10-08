# Setup Horizon Dashboard Service
class easystack::profile::horizon (
    String $listen_ip       = ip_for_network($::easystack::config::management_network),
    Array $controller_nodes = $::easystack::config::controller_nodes,
    String $public_endpoint = $::easystack::config::public_endpoint,
    String $secret_key      = $::easystack::config::horizon_secret_key,
) {
    # make sure the parameters are initialized
    include ::easystack

    include apache

    selinux::port { 'allow-horizon-httpd-80':
        seltype  => 'http_port_t',
        port     => 80,
        protocol => 'tcp',
        before   => Anchor['easystack::openstack::service_1::begin'],
    }

    firewalld_service { 'Allow horizon dashboard http - zone=internal':
        ensure  => present,
        service => 'http',
        zone    => 'internal',
        tag     => 'horizon-firewall',
    }

    firewalld_service { 'Allow horizon dashboard http - zone=public_mgmt':
        ensure  => present,
        service => 'http',
        zone    => 'public_mgmt',
        tag     => 'horizon-firewall',
    }

    firewalld_service { 'Allow horizon dashboard https - zone=public_mgmt':
        ensure  => present,
        service => 'https',
        zone    => 'public_mgmt',
        tag     => 'horizon-firewall',
    }

    $controller_nodes_ip = $controller_nodes.map |Hash $params| {
        $params[ip]
    }

    class { '::horizon':
        bind_address                   => $listen_ip,
        cache_backend                  => 'django.core.cache.backends.memcached.MemcachedCache',
        cache_server_ip                => $controller_nodes_ip,
        cache_server_port              => '11211',
        secret_key                     => $secret_key,
        django_debug                   => false,
        api_result_limit               => '1000',
        allowed_hosts                  => [$public_endpoint],
        servername                     => $::fqdn,
        django_session_engine          => 'django.contrib.sessions.backends.cache',
        keystone_url                   => "https://${public_endpoint}:5000/v3",
        keystone_multidomain_support   => true,
        keystone_default_domain        => 'Default',
        keystone_default_role          => 'user',
        api_versions                   => {
            'identity' => 3,
            'image'    => 2,
            'volume'   => 2,
        },
        neutron_options                => {
            'enable_router'             => false,
            'enable_quotas'             => false,
            'enable_distributed_router' => false,
            'enable_ha_router'          => false,
            'enable_lb'                 => false,
            'enable_firewall'           => false,
            'enable_vpn'                => false,
            'enable_fip_topology_check' => false,
            'timezone'                  => 'UTC',
        },
        default_theme                  => 'material',
        password_retrieve              => true,
        hypervisor_options             => {
            'can_set_mount_point' => true,
            'can_set_password'    => true,
        },
        enable_secure_proxy_ssl_header => true,
        secure_cookies                 => true,
    }

    # Currently it's not possible to set this option via the puppet-horizon module
    concat::fragment { 'local_settings.py_images_allow_location':
        target  => $::horizon::params::config_file,
        content => 'IMAGES_ALLOW_LOCATION = True',
        order   => '60',
    }

    Anchor['easystack::openstack::install_1::begin']
    -> Package <|tag == 'horizon-package'|>
    -> Anchor['easystack::openstack::install_1::end']

    Anchor['easystack::openstack::config_1::begin']
    -> Class['::horizon::wsgi::apache']
    -> Anchor['easystack::openstack::config_1::end']

    Firewalld_service <|tag == 'horizon-firewall'|>
    -> Anchor['easystack::openstack::service_1::begin']

}
