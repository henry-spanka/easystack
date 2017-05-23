# The role for the OpenStack compute nodes

class easystack::role::compute inherits ::easystack::role {
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

    $rabbit_password = $::easystack::config::rabbitmq_user_openstack_password
    $controller_host = $::easystack::config::controller_host

    class { 'nova':
        default_transport_url => "rabbit://openstack:${rabbit_password}@${controller_host}",
        image_service         => 'nova.image.glance.GlanceImageService',
        glance_api_servers    => "http://${controller_host}:9292",
        auth_strategy         => 'keystone',
        lock_path             => '/var/lib/nova/tmp',
    }

    $management_ip = ip_for_network($::easystack::config::management_network)

    # lint:ignore:duplicate_params
    nova_config {
        'DEFAULT/my_ip':           value => $management_ip;
        'DEFAULT/enabled_apis':    value => ['osapi_compute', 'metadata'];
        'vnc/novncproxy_base_url': value => "http://${controller_host}:6080/vnc_auto.html";
    }
    # lint:endignore

    class { 'nova::network::neutron':
        neutron_project_name        => 'services',
        neutron_project_domain_name => 'default',
        neutron_user_domain_name    => 'default',
        neutron_username            => 'neutron',
        neutron_password            => $::easystack::config::keystone_neutron_password,
        neutron_url                 => "http://${controller_host}:9696",
        neutron_auth_url            => "http://${controller_host}:35357/v3",
        firewall_driver             => 'nova.virt.firewall.NoopFirewallDriver',
        neutron_region_name         => $::easystack::config::keystone_region,
    }

    class { 'nova::placement':
        os_region_name      => $::easystack::config::keystone_region,
        project_domain_name => 'default',
        project_name        => 'services',
        auth_type           => 'password',
        auth_url            => "http://${controller_host}:35357/v3",
        username            => 'placement',
        password            => $::easystack::config::keystone_nova_placement_password,
    }

    class { 'nova::compute':
        vnc_enabled                   => true,
        vncserver_proxyclient_address => $management_ip,
        neutron_enabled               => true,
    }

    # We need to use QEMU for virtual servers and the old QEMU version
    # on CentOS 7 does not support disk discarding.
    if ($::is_virtual) {
        $hw_disk_discard = undef
        $libvirt_virt_type = 'qemu'
    } else {
        $hw_disk_discard = 'unmap'
        $libvirt_virt_type = 'kvm'
    }

    class { 'nova::compute::libvirt':
        libvirt_hw_disk_discard => $hw_disk_discard,
        vncserver_listen        => '0.0.0.0',
        libvirt_virt_type       => $libvirt_virt_type,
    }

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
    }

    class { '::neutron::agents::ml2::linuxbridge':
        local_ip     => ip_for_network($::easystack::config::neutron_network),
        tunnel_types => ['vxlan'],
    }

}
