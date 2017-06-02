# Setup Neutron Service
class easystack::profile::neutron (
    String $listen_ip        = ip_for_network($::easystack::config::management_network),
    Array $controller_nodes  = $::easystack::config::controller_nodes,
    String $vip              = $::easystack::config::controller_vip,
    String $db_password      = $::easystack::config::database_neutron_password,
    String $rabbit_password  = $::easystack::config::rabbitmq_user_openstack_password,
    String $neutron_password = $::easystack::config::keystone_neutron_password,
    String $region           = $::easystack::config::keystone_region,
    Boolean $master          = false,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::firewalld

    firewalld_port { 'Allow neutron api on port 9696 tcp':
        ensure   => present,
        zone     => 'public',
        port     => 9696,
        protocol => 'tcp',
        tag      => 'neutron-firewall',
        before   => Service['neutron-server'],
    }

    # RabbitMQ does not like FQDNs, therefore we need to connect
    # with only the hostnames
    $controller_nodes_hostname = $controller_nodes.map |Hash $params| {
        split($params[fqdn], '\.')[0]
    }

    $controller_nodes_hostname_auth = $controller_nodes_hostname.map |String $hostname| {
        "openstack:${rabbit_password}@${hostname}:15672"
    }

    $controller_nodes_hostname_auth_list = join($controller_nodes_hostname_auth, ',')

    class { '::neutron':
        enabled               => true,
        bind_host             => $listen_ip,
        default_transport_url => "rabbit://${controller_nodes_hostname_auth_list}",
        debug                 => false,
        auth_strategy         => 'keystone',
        lock_path             => '/var/lib/neutron/tmp',
        use_ssl               => false,
        core_plugin           => 'ml2',
        service_plugins       => ['router'],
        allow_overlapping_ips => true,
        rabbit_ha_queues      => true,
        amqp_durable_queues   => true,
        require               => Service['mysqld'],
    }

    $controller_nodes_ip = $controller_nodes.map |Hash $params| {
        $params[ip]
    }

    class { '::neutron::keystone::authtoken':
        project_name        => 'services',
        project_domain_name => 'default',
        user_domain_name    => 'default',
        memcached_servers   => $controller_nodes_ip,
        username            => 'neutron',
        password            => $neutron_password,
        auth_uri            => "http://${vip}:5000",
        auth_url            => "http://${vip}:35357",
    }

    class { '::neutron::server':
        database_connection => "mysql+pymysql://neutron:${db_password}@${vip}/neutron?charset=utf8",
        auth_strategy       => 'keystone',
    }

    class { '::neutron::server::notifications':
        username                           => 'nova',
        password                           => $::easystack::config::keystone_nova_password,
        notify_nova_on_port_status_changes => true,
        notify_nova_on_port_data_changes   => true,
        project_name                       => 'services',
        project_domain_name                => 'default',
        user_domain_name                   => 'default',
        auth_type                          => 'password',
        auth_url                           => "http://${vip}:35357",
        region_name                        => $region,
    }

    class { '::neutron::plugins::ml2':
        type_drivers          => ['flat', 'vlan', 'vxlan'],
        tenant_network_types  => ['vxlan'],
        mechanism_drivers     => ['linuxbridge', 'l2population'],
        extension_drivers     => ['port_security'],
        flat_networks         => ['provider'],
        vni_ranges            => ['1:1000'],
        enable_security_group => true,
    }

    if ($master) {
        class { '::neutron::keystone::auth':
            password            => $neutron_password,
            auth_name           => 'neutron',
            configure_endpoint  => true,
            configure_user      => true,
            configure_user_role => true,
            service_name        => 'nova',
            public_url          => "http://${vip}:9696",
            internal_url        => "http://${vip}:9696",
            admin_url           => "http://${vip}:9696",
            region              => $region,
            tenant              => 'services',
            require             => Class['keystone::endpoint'],
        }

        class { '::neutron::db::sync':
            before => Service['neutron-server'],
        }
    }

    # lint:ignore:duplicate_params
    neutron_config {
        'securitygroup/enable_ipset': value => true;
    }
    # lint:endignore

}
