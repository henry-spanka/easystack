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

    class { 'nova::compute::libvirt':
        libvirt_hw_disk_discard => 'unmap',
        vncserver_listen        => '0.0.0.0',
        libvirt_virt_type       => 'qemu',
    }

}
