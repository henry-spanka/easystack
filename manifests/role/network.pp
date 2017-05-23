# The role for the OpenStack network nodes

class easystack::role::network inherits ::easystack::role {
    # Make sure the time is synced on the controller nodes

    # TODO: Sync time with controller(s) instead
    class { 'chrony':
        pool_use => false,
        servers  => [
            '0.pool.ntp.org',
            '1.pool.ntp.org',
            '2.pool.ntp.org',
            '3.pool.ntp.org',
        ],
    }

    $neutron_db_password = $::easystack::config::database_neutron_password
    $rabbit_password = $::easystack::rabbitmq_user_openstack_password
    $controller_host = $::easystack::config::controller_host

    class { '::neutron::keystone::authtoken':
        project_name        => 'services',
        project_domain_name => 'default',
        user_domain_name    => 'default',
        memcached_servers   => ["${controller_host}:11211"],
        username            => 'neutron',
        password            => $::easystack::config::keystone_neutron_password,
        auth_uri            => "http://${controller_host}:5000",
        auth_url            => "http://${controller_host}:35357",
    }

    class { '::neutron':
        enabled               => true,
        bind_host             => $::fqdn,
        default_transport_url => "rabbit://openstack:${rabbit_password}@${controller_host}",
        debug                 => false,
        auth_strategy         => 'keystone',
        lock_path             => '/var/lib/neutron/tmp',
        use_ssl               => false,
        core_plugin           => 'ml2',
        service_plugins       => ['router'],
        allow_overlapping_ips => true,
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

    class { '::neutron::agents::l3':
        interface_driver => 'linuxbridge',
    }

    class { '::neutron::agents::dhcp':
        interface_driver         => 'linuxbridge',
        dhcp_driver              => 'neutron.agent.linux.dhcp.Dnsmasq',
        enable_isolated_metadata => true,
    }

    class { '::neutron::agents::ml2::linuxbridge':
        physical_interface_mappings => ['provider:eth2'],
        local_ip                    => ip_for_network($::easystack::config::neutron_network),
        l2_population               => true,
    }

    class { '::neutron::agents::metadata':
        metadata_ip   => ip_for_network($::easystack::config::management_network),
        shared_secret => $::easystack::config::neutron_metadata_shared_secret,
    }

    # lint:ignore:duplicate_params
    neutron_config {
        'securitygroup/enable_ipset': value => true;
    }
    # lint:endignore

}
