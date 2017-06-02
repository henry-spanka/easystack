# Setup Nova Service
class easystack::profile::nova (
    String $listen_ip          = ip_for_network($::easystack::config::management_network),
    Array $controller_nodes    = $::easystack::config::controller_nodes,
    String $vip                = $::easystack::config::controller_vip,
    String $db_password        = $::easystack::config::database_nova_password,
    String $rabbit_password    = $::easystack::config::rabbitmq_user_openstack_password,
    String $nova_password      = $::easystack::config::keystone_nova_password,
    String $placement_password = $::easystack::config::keystone_nova_placement_password,
    String $region             = $::easystack::config::keystone_region,
    Boolean $master            = false,
) {
    # make sure the parameters are initialized
    include ::easystack

    include apache

    selinux::port { 'allow-nova-api-httpd-8774':
        seltype  => 'http_port_t',
        port     => 8774,
        protocol => 'tcp',
        notify   => Class['apache::service'],
        require  => Class['apache'],
    }

    selinux::port { 'allow-nova-httpd-8778':
        seltype  => 'http_port_t',
        port     => 8778,
        protocol => 'tcp',
        notify   => Class['apache::service'],
        require  => Class['apache'],
    }

    include ::firewalld

    firewalld_port { 'Allow nova compute api on port 8774 tcp':
        ensure   => present,
        zone     => 'public',
        port     => 8774,
        protocol => 'tcp',
        tag      => 'nova-firewall',
        before   => Service['httpd'],
    }

    firewalld_port { 'Allow nova metadata api on port 8775 tcp':
        ensure   => present,
        zone     => 'public',
        port     => 8775,
        protocol => 'tcp',
        tag      => 'nova-firewall',
        before   => Service['httpd'],
    }

    firewalld_port { 'Allow nova placement api on port 8778 tcp':
        ensure   => present,
        zone     => 'public',
        port     => 8778,
        protocol => 'tcp',
        tag      => 'nova-firewall',
        before   => Service['httpd'],
    }

    firewalld_port { 'Allow nova vncproxy on port 6080 tcp':
        ensure   => present,
        zone     => 'public',
        port     => 6080,
        protocol => 'tcp',
        tag      => 'nova-firewall',
        before   => Service['nova-vncproxy'],
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

    class { 'nova':
        database_connection     => "mysql+pymysql://nova:${db_password}@${vip}/nova?charset=utf8",
        api_database_connection => "mysql+pymysql://nova:${db_password}@${vip}/nova_api?charset=utf8",
        default_transport_url   => "rabbit://${controller_nodes_hostname_auth_list}",
        image_service           => 'nova.image.glance.GlanceImageService',
        glance_api_servers      => "http://${vip}:9292",
        auth_strategy           => 'keystone',
        lock_path               => '/var/lib/nova/tmp',
        rabbit_ha_queues        => true,
        amqp_durable_queues     => true,
        require                 => Service['mysqld'],
    }

    $controller_nodes_ip = $controller_nodes.map |Hash $params| {
        $params[ip]
    }

    class { '::nova::keystone::authtoken':
        project_name        => 'services',
        project_domain_name => 'default',
        user_domain_name    => 'default',
        memcached_servers   => $controller_nodes_ip,
        username            => 'nova',
        password            => $nova_password,
    }

    if ($master) {
        class { '::nova::keystone::auth':
            password            => $nova_password,
            auth_name           => 'nova',
            configure_endpoint  => true,
            configure_user      => true,
            configure_user_role => true,
            service_name        => 'nova',
            public_url          => "http://${vip}:8774/v2.1",
            internal_url        => "http://${vip}:8774/v2.1",
            admin_url           => "http://${vip}:8774/v2.1",
            region              => $region,
            tenant              => 'services',
            require             => Class['::easystack::profile::keystone'],
        }

        class { '::nova::keystone::auth_placement':
            password            => $placement_password,
            auth_name           => 'placement',
            configure_endpoint  => true,
            configure_user      => true,
            configure_user_role => true,
            service_name        => 'placement',
            public_url          => "http://${vip}:8778/placement",
            internal_url        => "http://${vip}:8778/placement",
            admin_url           => "http://${vip}:8778/placement",
            region              => $region,
            tenant              => 'services',
            require             => Class['::easystack::profile::keystone'],
        }

        include ::nova::cell_v2::simple_setup
    }

    class { 'nova::api':
        enabled_apis     => ['osapi_compute', 'metadata'],
        api_bind_address => $listen_ip,
        metadata_listen  => $listen_ip,
        service_name     => 'httpd',
        sync_db          => $master,
        sync_db_api      => $master,
    }

    class { '::nova::wsgi::apache':
        ssl        => false,
        bind_host  => $listen_ip,
        servername => $::fqdn,
    }

    class { 'nova::wsgi::apache_placement':
        servername => $::fqdn,
        api_port   => 8778,
        ssl        => false,
        bind_host  => $listen_ip,
    }

    class { 'nova::conductor': }
    class { 'nova::consoleauth': }
    class { 'nova::vncproxy':
        host => $listen_ip,
    }
    class { 'nova::scheduler': }

    class { 'nova::placement':
        os_region_name      => $region,
        project_domain_name => 'default',
        project_name        => 'services',
        auth_type           => 'password',
        auth_url            => "http://${vip}:35357/v3",
        username            => 'placement',
        password            => $placement_password,
    }

    # lint:ignore:duplicate_params
    nova_config {
        'DEFAULT/my_ip':                              value => $listen_ip;
        'vnc/enabled':                                value => true;
        'vnc/vncserver_listen':                       value => $listen_ip;
        'vnc/vncserver_proxyclient_address':          value => $vip;
        'scheduler/discover_hosts_in_cells_interval': value => 300;
    }
    # lint:endignore

}
