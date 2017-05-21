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
                'bind-address'           => $management_ip,
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

    apache::mod { 'wsgi': }

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
    -> file { '/etc/httpd/conf.d/wsgi-keystone.conf':
        ensure  => 'link',
        target  => '/usr/share/keystone/wsgi-keystone.conf',
        notify  => Class['apache::service'],
        require => Class['apache'],
    }

    $keystone_db_password = $::easystack::config::database_keystone_password
    $keystone_admin_password = $::easystack::config::keystone_admin_password

    class { 'keystone':
        catalog_type        => 'sql',
        admin_token         => $::easystack::config::keystone_admin_token,
        database_connection => "mysql://keystone:${keystone_db_password}@localhost/keystone",
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
        require   => [
            Class['keystone::endpoint'],
            Class['keystone::roles::admin'],
        ],
    }

}
