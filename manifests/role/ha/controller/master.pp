# The role for the OpenStack master controller
class easystack::role::ha::controller::master inherits ::easystack::role {

    # Sync time
    include ::easystack::profile::chrony

    # Install and configure Memcached
    include ::easystack::profile::memcached

    # Install and configure MariaDB
    class { '::easystack::profile::mariadb':
        master => true,
    }

    # If there are no other servers up and we are the master, the cluster
    # needs to be bootstrapped. This happens before the service is managed
    include ::easystack::profile::mariadb::galera_bootstrap

    include ::easystack::profile::mariadb::mysqlchk

    # Setup RabbitMQ
    include ::easystack::profile::rabbitmq

    rabbitmq_user { 'openstack':
        admin    => false,
        password => $::easystack::config::rabbitmq_user_openstack_password,
    }
    rabbitmq_user_permissions { 'openstack@/':
        configure_permission => '.*',
        read_permission      => '.*',
        write_permission     => '.*',
    }

    rabbitmq_policy { 'ha-all@/':
        pattern    => '.*',
        priority   => 0,
        applyto    => 'all',
        definition => {
            'ha-mode'      => 'all',
        },
    }

    # Setup corosync
    class { '::easystack::profile::corosync':
        master => true,
    }

    # Make sure MariaDB Services start before pcsd
    # as the slaves can not start mariadb if the master has not initialized the
    # database yet
    Service['mysqld'] -> Service['pcsd']

    cs_primitive { 'vip':
        primitive_class => 'ocf',
        primitive_type  => 'IPaddr2',
        provided_by     => 'heartbeat',
        parameters      => {
            'ip'           => $::easystack::config::controller_vip,
            'cidr_netmask' => '24'
        },
        operations      => {
            'monitor' => {
                'interval' => '30s',
            }
        },
        require         => Class['::easystack::profile::corosync'],
    }

    # Setup haproxy
    include ::easystack::profile::haproxy

    # Configure haproxy resources
    include ::easystack::profile::haproxy::keystone
    include ::easystack::profile::haproxy::galera

    # Setup Haproxy Corosync service and VIP
    cs_primitive { 'haproxy':
        ensure          => present,
        primitive_class => 'systemd',
        primitive_type  => 'haproxy',
        operations      => {
            'monitor' => {
                'interval' => '1s',
            }
        },
        require         => Class['haproxy'],
    }

    cs_clone { 'haproxy-clone':
        ensure    => present,
        primitive => 'haproxy',
        require   => Cs_primitive['haproxy'],
    }

    cs_order { 'vip_before_haproxy':
        first   => 'vip',
        second  => 'haproxy-clone',
        kind    => 'Optional',
        require => [
            Cs_clone['haproxy-clone'],
            Cs_primitive['vip'],
        ],
    }

    cs_colocation { 'vip_with_haproxy':
        primitives => ['haproxy-clone', 'vip'],
        require    => Cs_order['vip_before_haproxy'],
    }

    # Setup apache
    class { 'apache':
        default_vhost => false,
        servername    => $::fqdn,
    }

    # Setup keystone
    # Configure keystone mySQL database
    mysql::db { 'keystone':
        user     => 'keystone',
        password => mysql_password($::easystack::config::database_keystone_password),
        host     => 'localhost',
        grant    => ['ALL'],
    }
    -> mysql_user { 'keystone@%':
        ensure        => 'present',
        password_hash => mysql_password($::easystack::config::database_keystone_password),
    }
    -> mysql_grant { 'keystone@%/keystone.*':
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['ALL'],
        table      => 'keystone.*',
        user       => 'keystone@%',
    }

    class { '::easystack::profile::keystone':
        master => true,
    }

    # Setup httpd corosync service
    cs_primitive { 'httpd':
        ensure          => present,
        primitive_class => 'systemd',
        primitive_type  => 'httpd',
        require         => [
            Class['apache'],
            Exec['restart_keystone'],
        ],
        operations      => {
            'monitor' => {
                'interval' => '5s',
            }
        },
    }

    cs_clone { 'httpd-clone':
        ensure     => present,
        primitive  => 'httpd',
        require    => Cs_primitive['httpd'],
        interleave => true,
    }

}
