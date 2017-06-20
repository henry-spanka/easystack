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
    Service['haproxy'] -> Service['pcsd']

    # Install Haproxy and Apache before autenticating as otherwise a warning message
    # will be displayed that the services can not be found by pacemaker
    Package['haproxy'] -> Class['::easystack::profile::corosync']
    Package['httpd'] -> Class['::easystack::profile::corosync']
    Service['haproxy'] -> Service['mysqld']
    Service['mysqld'] -> Service['httpd']

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
            },
            'start'   => {
                'timeout'  => '300s',
                'interval' => '0s',
            },
            'stop'    => {
                'timeout'  => '120s',
                'interval' => '0s',
            },
        },
    }

    cs_clone { 'httpd-clone':
        ensure     => present,
        primitive  => 'httpd',
        require    => Cs_primitive['httpd'],
        interleave => true,
    }

    # Configure glance
    # Configure glance mySQL database
    mysql::db { 'glance':
        user     => 'glance',
        password => mysql_password($::easystack::config::database_glance_password),
        host     => 'localhost',
        grant    => ['ALL'],
    }
    -> mysql_user { 'glance@%':
        ensure        => 'present',
        password_hash => mysql_password($::easystack::config::database_glance_password),
    }
    -> mysql_grant { 'glance@%/glance.*':
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['ALL'],
        table      => 'glance.*',
        user       => 'glance@%',
    }

    class { '::easystack::profile::glance':
        master => true,
    }

    include ::easystack::profile::glance::backend::rbd

    # Setup Glance Haproxy resources
    include ::easystack::profile::haproxy::glance_api
    include ::easystack::profile::haproxy::glance_registry

    # Setup glance corosync service
    cs_primitive { 'openstack-glance-api':
        ensure          => present,
        primitive_class => 'systemd',
        primitive_type  => 'openstack-glance-api',
        require         => Service['glance-api'],
        operations      => {
            'monitor' => {
                'interval' => '5s',
            }
        },
    }

    cs_clone { 'openstack-glance-api-clone':
        ensure     => present,
        primitive  => 'openstack-glance-api',
        require    => Cs_primitive['openstack-glance-api'],
        interleave => true,
    }

    cs_primitive { 'openstack-glance-registry':
        ensure          => present,
        primitive_class => 'systemd',
        primitive_type  => 'openstack-glance-registry',
        require         => Service['glance-registry'],
        operations      => {
            'monitor' => {
                'interval' => '5s',
            }
        },
    }

    cs_clone { 'openstack-glance-registry-clone':
        ensure     => present,
        primitive  => 'openstack-glance-registry',
        require    => Cs_primitive['openstack-glance-registry'],
        interleave => true,
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
        password_hash => mysql_password($::easystack::config::database_nova_password),
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

    include ::easystack::profile::nova
    include ::easystack::profile::nova::cache

    include ::easystack::profile::nova::authtoken

    include ::easystack::profile::nova::auth
    include ::easystack::profile::nova::auth_placement
    include ::easystack::profile::nova::cell_v2

    class { '::easystack::profile::nova::api':
        sync_db => true,
    }

    include ::easystack::profile::nova::placement

    include ::easystack::profile::nova::conductor
    include ::easystack::profile::nova::consoleauth
    include ::easystack::profile::nova::vncproxy
    include ::easystack::profile::nova::scheduler

    include ::easystack::profile::nova::neutron

    Service['mysqld'] -> Service['nova-api']
    Service['mysqld'] -> Service['nova-conductor']
    Service['mysqld'] -> Service['nova-consoleauth']
    Service['mysqld'] -> Service['nova-vncproxy']
    Service['mysqld'] -> Service['nova-scheduler']

    # Setup Glance Haproxy resources
    include ::easystack::profile::haproxy::nova_compute_api
    include ::easystack::profile::haproxy::nova_metadata_api
    include ::easystack::profile::haproxy::nova_placement_api
    include ::easystack::profile::haproxy::nova_vncproxy

    # Setup Horizon
    include ::easystack::profile::horizon

    # Setup Horizon Haproxy resource
    include ::easystack::profile::haproxy::horizon

    # Configure Neutron server on controller

    # Setup database for Neutron
    mysql::db { 'neutron':
        user     => 'neutron',
        password => mysql_password($::easystack::config::database_neutron_password),
        host     => 'localhost',
        grant    => ['ALL'],
    }
    -> mysql_user { 'neutron@%':
        ensure        => 'present',
        password_hash => mysql_password($::easystack::config::database_neutron_password),
    }
    -> mysql_grant { 'neutron@%/neutron.*':
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['ALL'],
        table      => 'neutron.*',
        user       => 'neutron@%',
    }

    include ::easystack::profile::neutron

    include ::easystack::profile::neutron::authtoken

    class { '::easystack::profile::neutron::server':
        sync_db => true,
    }

    include ::easystack::profile::neutron::plugins::ml2

    include ::easystack::profile::neutron::auth

    Service['mysqld'] -> Service['neutron-server']

    # Setup Neutron Haproxy resources
    include ::easystack::profile::haproxy::neutron_api

    # Setup database for Cinder
    mysql::db { 'cinder':
        user     => 'cinder',
        password => mysql_password($::easystack::config::database_cinder_password),
        host     => 'localhost',
        grant    => ['ALL'],
    }
    -> mysql_user { 'cinder@%':
        ensure        => 'present',
        password_hash => mysql_password($::easystack::config::database_cinder_password),
    }
    -> mysql_grant { 'cinder@%/cinder.*':
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['ALL'],
        table      => 'cinder.*',
        user       => 'cinder@%',
    }

    # Setup Cinder
    include ::easystack::profile::cinder
    include ::easystack::profile::cinder::authtoken

    class { '::easystack::profile::cinder::api':
        sync_db => true,
    }

    include ::easystack::profile::cinder::auth

    include ::easystack::profile::cinder::scheduler
    include ::easystack::profile::cinder::volume

    include ::easystack::profile::cinder::backends

    include ::easystack::profile::cinder::backends::ceph

    include ::easystack::profile::haproxy::cinder_api

    Service['mysqld'] -> Service['cinder-api']

}
