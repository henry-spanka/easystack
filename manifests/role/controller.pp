# The role for the OpenStack controller
class easystack::role::controller inherits ::easystack::role {
    # Make sure the time is synced on the controller nodes
    class { 'chrony':
        pool_use => false,
        servers  => [
            '0.pool.ntp.org',
            '1.pool.ntp.org',
            '2.pool.ntp.org',
            '3.pool.ntp.org',
        ],
    }

    $management_network = $::easystack::config::management_network
    $management_ip      = ip_for_network($management_network)

    # Setup Controller SQL databases
    class { '::mysql::server':
        package_name            => 'mariadb-server',
        root_password           => $::easystack::config::database_root_password,
        remove_default_accounts => true,
        override_options        => {
            'mysqld' => {
                'bind-address'           => '0.0.0.0',
                'default-storage-engine' => 'innodb',
                'innodb_file_per_table'  => true,
                'max_connections'        => 4096,
                'collation-server'       => 'utf8_general_ci',
                'character-set-server'   => 'utf8',
            }
        }
    }

    # Install MySQL python library
    package { 'python2-PyMySQL':
        ensure => installed,
        name   => 'python2-PyMySQL'
    }

    # Install and configure RabbitMQ
    class { '::rabbitmq':
        delete_guest_user => true,
    }
    rabbitmq_user { 'openstack':
        admin    => false,
        password => $::easystack::config::rabbitmq_user_openstack_password,
    }
    rabbitmq_user_permissions { 'openstack@/':
        configure_permission => '.*',
        read_permission      => '.*',
        write_permission     => '.*',
    }

    # Install and configure Memcached
    class { 'memcached':
        listen_ip  => "127.0.0.1,::1,${management_ip}",
        max_memory => '20%',
    }
    package { 'python-memcached':
        ensure => installed,
        name   => 'python-memcached',
    }

    # Configure keystone mySQL database
    mysql::db { 'keystone':
        user     => 'keystone',
        password => $::easystack::config::database_keystone_password_hash,
        host     => 'localhost',
        grant    => ['ALL'],
    }
    -> mysql_user { 'keystone@%':
        ensure        => 'present',
        password_hash => $::easystack::config::database_keystone_password_hash,
    }
    -> mysql_grant { 'keystone@%/keystone.*':
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['ALL'],
        table      => 'keystone.*',
        user       => 'keystone@%',
    }

    class { 'apache':
        default_vhost => false,
        servername    => $::fqdn,
    }

    class { 'keystone::wsgi::apache':
        servername => $::fqdn,
        ssl        => false,
    }

    -> selinux::port { 'allow-keystone-httpd-5000':
        seltype  => 'http_port_t',
        port     => 5000,
        protocol => 'tcp',
    }
    -> selinux::port { 'allow-keystone-httpd-35357':
        seltype  => 'http_port_t',
        port     => 35357,
        protocol => 'tcp',
    }
    -> selinux::boolean { 'httpd_can_network_connect_db':
        ensure => 'on',
    }

    $keystone_db_password = $::easystack::config::database_keystone_password
    $keystone_admin_password = $::easystack::config::keystone_admin_password

    class { 'keystone':
        catalog_type        => 'sql',
        admin_token         => $::easystack::config::keystone_admin_token,
        database_connection => "mysql+pymysql://keystone:${keystone_db_password}@localhost/keystone",
        token_provider      => 'fernet',
        service_name        => 'httpd',
        require             => Class['::mysql::server'],
    }

    Package['openstack-keystone'] -> Class['apache::service']

    class { 'keystone::roles::admin':
        email    => $::easystack::config::keystone_admin_email,
        password => $keystone_admin_password,
        require  => [
            Class['apache::service'],
            Class['::mysql::server'],
        ],
    }

    # Installs the service user endpoint.
    class { 'keystone::endpoint':
        public_url   => "http://${::fqdn}:5000/v3/",
        admin_url    => "http://${::fqdn}:35357/v3/",
        internal_url => "http://${::fqdn}:5000/v3/",
        region       => $::easystack::config::keystone_region,
        require      => [
            Class['apache::service'],
            Class['::mysql::server'],
        ],
    }

    # Remove the admin_token_auth paste pipeline.
    # After the first puppet run this requires setting keystone v3
    # admin credentials via /root/openrc or as environment variables.
    include keystone::disable_admin_token_auth

    file { '/root/openrc':
        ensure    => file,
        content   => template('easystack/keystone/openrc.erb'),
        show_diff => false,
        owner     => 'root',
        group     => 'root',
        mode      => '0600', # Only root should be able to read the credentials
        require   => [
            Class['keystone::endpoint'],
            Class['keystone::roles::admin'],
        ],
    }

    # Configure glance mySQL database
    mysql::db { 'glance':
        user     => 'glance',
        password => $::easystack::config::database_glance_password_hash,
        host     => 'localhost',
        grant    => ['ALL'],
    }
    -> mysql_user { 'glance@%':
        ensure        => 'present',
        password_hash => $::easystack::config::database_glance_password_hash,
    }
    -> mysql_grant { 'glance@%/glance.*':
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['ALL'],
        table      => 'glance.*',
        user       => 'glance@%',
    }

    $glance_db_password = $::easystack::config::database_glance_password

    class { '::glance': }

    glance_api_config {
        'paste_deploy/flavor':
            ensure => present,
            value  => 'keystone',
    }

    class { '::glance::api::db':
        database_connection => "mysql+pymysql://glance:${glance_db_password}@localhost/glance",
        notify              => Service['glance-api'],
    }

    class { '::glance::api::authtoken':
        project_name        => 'services',
        project_domain_name => 'default',
        user_domain_name    => 'default',
        memcached_servers   => ['127.0.0.1:11211'],
        username            => 'glance',
        password            => $::easystack::config::keystone_glance_password,
        notify              => Service['glance-api'],
    }

    glance_registry_config {
        'paste_deploy/flavor':
            ensure => present,
            value  => 'keystone',
    }

    class { '::glance::registry::db':
        database_connection => "mysql+pymysql://glance:${glance_db_password}@localhost/glance",
        notify              => Service['glance-registry'],
    }

    class { '::glance::registry::authtoken':
        project_name        => 'services',
        project_domain_name => 'default',
        user_domain_name    => 'default',
        memcached_servers   => ['127.0.0.1:11211'],
        username            => 'glance',
        password            => $::easystack::config::keystone_glance_password,
        notify              => Service['glance-registry'],
    }

    class { 'glance::backend::file': }

    class { '::glance::keystone::auth':
        password            => $::easystack::config::keystone_glance_password,
        auth_name           => 'glance',
        configure_endpoint  => true,
        configure_user      => true,
        configure_user_role => true,
        service_name        => 'glance',
        public_url          => "http://${::fqdn}:9292",
        internal_url        => "http://${::fqdn}:9292",
        admin_url           => "http://${::fqdn}:9292",
        region              => $::easystack::config::keystone_region,
        tenant              => 'services',
        require             => Class['keystone::endpoint'],
    }

    service { 'glance-api':
        ensure     => 'running',
        name       => 'openstack-glance-api',
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        tag        => 'glance-service',
    }

    service { 'glance-registry':
        ensure     => 'running',
        name       => 'openstack-glance-registry',
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        tag        => 'glance-service',
    }

    # Configure Compute service Nova on controller node

    # Configure nova mySQL databases
    mysql::db { 'nova_api':
        user     => 'nova',
        password => $::easystack::config::database_nova_password,
        host     => 'localhost',
        grant    => ['ALL'],
    }
    -> mysql::db { 'nova':
        user     => 'nova',
        password => $::easystack::config::database_nova_password,
        host     => 'localhost',
        grant    => ['ALL'],
    }
    -> mysql::db { 'nova_cell0':
        user     => 'nova',
        password => $::easystack::config::database_nova_password,
        host     => 'localhost',
        grant    => ['ALL'],
    }
    -> mysql_user { 'nova@%':
        ensure        => 'present',
        password_hash => $::easystack::config::database_nova_password_hash,
    }
    -> mysql_grant { 'nova@%/nova_api.*':
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['ALL'],
        table      => 'nova_api.*',
        user       => 'nova@%',
    }
    -> mysql_grant { 'nova@%/nova.*':
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['ALL'],
        table      => 'nova.*',
        user       => 'nova@%',
    }
    -> mysql_grant { 'nova@%/nova_cell0.*':
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['ALL'],
        table      => 'nova_cell0.*',
        user       => 'nova@%',
    }

    $nova_db_password = $::easystack::config::database_nova_password
    $rabbit_password = $::easystack::rabbitmq_user_openstack_password

    class { 'nova':
        database_connection     => "mysql+pymysql://nova:${nova_db_password}@localhost/nova?charset=utf8",
        api_database_connection => "mysql+pymysql://nova:${nova_db_password}@localhost/nova_api?charset=utf8",
        default_transport_url   => "rabbit://openstack:${rabbit_password}@localhost",
        image_service           => 'nova.image.glance.GlanceImageService',
        glance_api_servers      => 'http://localhost:9292',
        auth_strategy           => 'keystone',
        lock_path               => '/var/lib/nova/tmp',
    }

    class { '::nova::keystone::authtoken':
        project_name        => 'services',
        project_domain_name => 'default',
        user_domain_name    => 'default',
        memcached_servers   => ['127.0.0.1:11211'],
        username            => 'nova',
        password            => $::easystack::config::keystone_nova_password,
    }

    class { '::nova::keystone::auth':
        password            => $::easystack::config::keystone_nova_password,
        auth_name           => 'nova',
        configure_endpoint  => true,
        configure_user      => true,
        configure_user_role => true,
        service_name        => 'nova',
        public_url          => "http://${::fqdn}:8774/v2.1",
        internal_url        => "http://${::fqdn}:8774/v2.1",
        admin_url           => "http://${::fqdn}:8774/v2.1",
        region              => $::easystack::config::keystone_region,
        tenant              => 'services',
        require             => Class['keystone::endpoint'],
    }

    class { '::nova::keystone::auth_placement':
        password            => $::easystack::config::keystone_nova_placement_password,
        auth_name           => 'placement',
        configure_endpoint  => true,
        configure_user      => true,
        configure_user_role => true,
        service_name        => 'placement',
        public_url          => "http://${::fqdn}:8778",
        internal_url        => "http://${::fqdn}:8778",
        admin_url           => "http://${::fqdn}:8778",
        region              => $::easystack::config::keystone_region,
        tenant              => 'services',
        require             => Class['keystone::endpoint'],
    }

    class { 'nova::api':
        enabled_apis => ['osapi_compute', 'metadata']
    }

    class { 'nova::conductor': }
    class { 'nova::consoleauth': }
    class { 'nova::vncproxy': }
    class { 'nova::scheduler': }

    class { 'nova::placement':
        os_region_name      => $::easystack::config::keystone_region,
        project_domain_name => 'default',
        project_name        => 'services',
        auth_type           => 'password',
        auth_url            => "http://${::fqdn}:35357/v3",
        username            => 'placement',
        password            => $::easystack::config::keystone_nova_placement_password,
    }

    selinux::port { 'allow-keystone-httpd-8778':
        seltype  => 'http_port_t',
        port     => 8778,
        protocol => 'tcp',
        notify   => Class['apache::service'],
        require  => Class['apache'],
    }

    class { 'nova::wsgi::apache_placement':
        servername => $::fqdn,
        api_port   => 8778,
        ssl        => false,
    }

    # lint:ignore:duplicate_params
    nova_config {
        'DEFAULT/my_ip':                     value => $management_ip;
        'DEFAULT/use_neutron':               value => true;
        'DEFAULT/firewall_driver':           value => 'nova.virt.firewall.NoopFirewallDriver';
        'vnc/enabled':                       value => true;
        'vnc/vncserver_listen':              value => $management_ip;
        'vnc/vncserver_proxyclient_address': value => $management_ip;
    }
    # lint:endignore

    # Only on Primary Controller?
    include ::nova::cell_v2::simple_setup

}
