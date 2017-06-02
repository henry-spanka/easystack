# Setup Horizon Dashboard Service
class easystack::profile::horizon (
    String $listen_ip       = ip_for_network($::easystack::config::management_network),
    Array $controller_nodes = $::easystack::config::controller_nodes,
    String $vip             = $::easystack::config::controller_vip,
    String $secret_key      = $::easystack::config::horizon_secret_key,
) {
    # make sure the parameters are initialized
    include ::easystack

    include apache

    selinux::port { 'allow-horizon-httpd-80':
        seltype  => 'http_port_t',
        port     => 80,
        protocol => 'tcp',
        notify   => Class['apache::service'],
        require  => Class['apache'],
    }

    firewalld_service { 'Allow horizon dashboard http':
        ensure  => present,
        service => 'http',
        zone    => 'public',
        tag     => 'horizon-firewall',
        before  => Service['httpd'],
    }

    $controller_nodes_ip = $controller_nodes.map |Hash $params| {
        $params[ip]
    }

    class { '::horizon':
        bind_address                 => $listen_ip,
        cache_backend                => 'django.core.cache.backends.memcached.MemcachedCache',
        cache_server_ip              => $controller_nodes_ip,
        cache_server_port            => '11211',
        secret_key                   => $secret_key,
        django_debug                 => false,
        api_result_limit             => '1000',
        allowed_hosts                => [$vip],
        servername                   => $::fqdn,
        django_session_engine        => 'django.contrib.sessions.backends.cache',
        keystone_url                 => "http://${vip}:5000/v3",
        keystone_multidomain_support => true,
        keystone_default_domain      => 'Default',
        keystone_default_role        => 'user',
        api_versions                 => {
            'identity' => 3,
            'image'    => 2,
            'volume'   => 2,
        },
        neutron_options              => {
            'enable_router'             => true,
            'enable_quotas'             => false,
            'enable_distributed_router' => false,
            'enable_ha_router'          => false,
            'enable_lb'                 => false,
            'enable_firewall'           => false,
            'enable_vpn'                => false,
            'enable_fip_topology_check' => false,
            'timezone'                  => 'UTC',
        },
        default_theme                => 'material',
    }

}
