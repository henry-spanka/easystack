# The role for the OpenStack master controller
class easystack::role::ha::controller::master inherits ::easystack::role {
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

    $management_ip = ip_for_network($::easystack::config::management_network)

    # Install and configure Memcached
    class { 'memcached':
        listen_ip  => "127.0.0.1,::1,${management_ip}",
        max_memory => '20%',
    }


    # Setup MariaDB
    yumrepo { 'MariaDB':
        baseurl  => 'http://yum.mariadb.org/10.1/centos7-amd64',
        descr    => 'MariaDB 10.1',
        enabled  => 1,
        gpgcheck => 1,
        gpgkey   => 'https://yum.mariadb.org/RPM-GPG-KEY-MariaDB',
    }

    package { 'galera':
        ensure => installed,
    }

    package { 'rsync':
        ensure => installed,
    }

    package { 'socat':
        ensure => installed,
    }

    package { 'nmap':
        ensure => installed,
    }

    package { 'percona-xtrabackup':
        ensure => installed,
    }

    $server_list = join($::easystack::config::controller_servers, ' ')
    $server_list_comma = join($::easystack::config::controller_servers, ',')
    $database_sstuser_password = $easystack::config::database_sstuser_password

    # Setup Controller SQL databases
    class { '::mysql::server':
        package_name            => 'MariaDB-server',
        root_password           => $::easystack::config::database_root_password,
        remove_default_accounts => true,
        create_root_my_cnf      => true,
        create_root_user        => true,
        override_options        => {
            'mysqld' => {
                'bind-address'                   => '0.0.0.0',
                'default-storage-engine'         => 'innodb',
                'innodb_file_per_table'          => true,
                'max_connections'                => 4096,
                'collation-server'               => 'utf8_general_ci',
                'character-set-server'           => 'utf8',
                'wsrep_node_address'             => $management_ip,
                'wsrep_provider'                 => '/usr/lib64/galera/libgalera_smm.so',
                'wsrep_cluster_name'             => 'openstack_galera_cluster',
                'wsrep_cluster_address'          => "gcomm://${server_list_comma}",
                'wsrep_slave_threads'            => '8',
                'wsrep_sst_method'               => 'xtrabackup-v2',
                'wsrep_sst_auth'                 => "sstuser:${database_sstuser_password}",
                'binlog_format'                  => 'ROW',
                'innodb_locks_unsafe_for_binlog' => '1',
                'innodb_autoinc_lock_mode'       => '2',
                'query_cache_size'               => '0',
                'query_cache_type'               => '0',
                'wsrep_node_incoming_address'    => $management_ip,
                'wsrep_sst_receive_address'      => $management_ip,
                'wsrep_on'                       => 'ON',
            }
        }
    }

    # If there are no other servers up and we are the master, the cluster
    # needs to be bootstrapped. This happens before the service is managed

    exec { 'bootstrap_galera_cluster':
        command  => '/usr/bin/galera_new_cluster',
        unless   => "nmap -Pn -p 4567 ${server_list} | grep -q '4567/tcp open'",
        require  => Class['mysql::server::installdb'],
        before   => Service['mysqld'],
        provider => shell,
        path     => '/usr/bin:/bin:/usr/sbin:/sbin'
    }

    file { '/var/log/mariadb':
        ensure => 'directory',
        before => Class['mysql::server::install'],
    }

    file { '/var/run/mariadb':
        ensure  => 'directory',
        owner   => 'mysql',
        group   => 'mysql',
        require => Class['mysql::server::install'],
        before  => Class['mysql::server::installdb'],
    }

    mysql_user { 'sstuser@localhost':
        ensure        => 'present',
        password_hash => mysql_password($::easystack::config::database_sstuser_password),
    }
    -> mysql_grant { 'sstuser@localhost/*.*':
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['RELOAD', 'LOCK TABLES', 'REPLICATION CLIENT'],
        table      => '*.*',
        user       => 'sstuser@localhost',
    }

    selinux::port { 'allow-galera-tcp-4567':
        seltype  => 'mysqld_port_t',
        port     => 4567,
        protocol => 'tcp',
        require  => Class['mysql::server::install'],
        before   => Class['mysql::server::installdb'],
    }

    selinux::port { 'allow-galera-udp-4567':
        seltype  => 'mysqld_port_t',
        port     => 4567,
        protocol => 'udp',
        require  => Class['mysql::server::install'],
        before   => Class['mysql::server::installdb'],
    }

    selinux::port { 'allow-galera-tcp-4444':
        seltype  => 'mysqld_port_t',
        port     => 4444,
        protocol => 'tcp',
        require  => Class['mysql::server::install'],
        before   => Class['mysql::server::installdb'],
    }

    selinux::port { 'allow-galera-tcp4568':
        seltype  => 'mysqld_port_t',
        port     => 4568,
        protocol => 'tcp',
        require  => Class['mysql::server::install'],
        before   => Class['mysql::server::installdb'],
    }

    # See: https://jira.mariadb.org/browse/MDEV-10767
    selinux::module { 'mysql_wsrep-selinux':
        ensure    => 'present',
        source_te => 'puppet:///modules/easystack/selinux/mysql_wsrep-selinux.te',
        require   => Class['mysql::server::install'],
        before    => Class['mysql::server::installdb'],
    }

    # See: https://jira.mariadb.org/browse/MDEV-9852
    selinux::module { 'mysql_setpgid-selinux':
        ensure    => 'present',
        source_te => 'puppet:///modules/easystack/selinux/mysql_setpgid-selinux.te',
        require   => Class['mysql::server::install'],
        before    => Class['mysql::server::installdb'],
    }

    class { 'firewalld': }

    firewalld_port { 'Allow galera replication on port 4444 tcp':
      ensure   => present,
      zone     => 'public',
      port     => 4444,
      protocol => 'tcp',
      before   => Class['mysql::server::installdb'],
    }

    firewalld_port { 'Allow galera replication on port 4567 tcp':
      ensure   => present,
      zone     => 'public',
      port     => 4567,
      protocol => 'tcp',
      before   => Class['mysql::server::installdb'],
    }

    firewalld_port { 'Allow galera replication on port 4568 tcp':
      ensure   => present,
      zone     => 'public',
      port     => 4568,
      protocol => 'tcp',
      before   => Class['mysql::server::installdb'],
    }

    firewalld_port { 'Allow galera replication on port 4567 udp':
      ensure   => present,
      zone     => 'public',
      port     => 4567,
      protocol => 'udp',
      before   => Class['mysql::server::installdb'],
    }

    firewalld_service { 'Allow mysql':
      ensure  => present,
      service => 'mysql',
      zone    => 'public',
      before  => Class['mysql::server::installdb'],
    }

    # Dependencies definition
    Yumrepo['MariaDB']
    -> Package['galera']
    -> Package['rsync']
    -> Package['socat']
    -> Package['nmap']
    -> Package['percona-xtrabackup']
    -> Class['::mysql::server']

    # RabbitMQ does not like FQDNs, therefore we need to establish a cluster
    # with only the hostnames
    $controller_servers_rabbit = $::easystack::config::controller_servers.map |$server| {
        split($server, '\.')[0]
    }

    # Install and configure RabbitMQ
    class { '::rabbitmq':
        delete_guest_user          => true,
        config_cluster             => true,
        cluster_nodes              => $controller_servers_rabbit,
        cluster_node_type          => 'disc',
        erlang_cookie              => $::easystack::config::rabbitmq_erlang_cookie,
        wipe_db_on_cookie_change   => true,
        cluster_partition_handling => 'pause_minority',
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

    rabbitmq_policy { 'ha-all@/':
        pattern    => '.*',
        priority   => 0,
        applyto    => 'all',
        definition => {
            'ha-mode'      => 'all',
        },
    }

    firewalld_port { 'Allow rabbitmq cluster on port 4369 tcp':
      ensure   => present,
      zone     => 'public',
      port     => 4369,
      protocol => 'tcp',
      before   => Class['::rabbitmq'],
    }

    firewalld_port { 'Allow rabbitmq cluster on port 25672 tcp':
      ensure   => present,
      zone     => 'public',
      port     => 25672,
      protocol => 'tcp',
      before   => Class['::rabbitmq'],
    }

    firewalld_port { 'Allow rabbitmq on port 5672 tcp':
      ensure   => present,
      zone     => 'public',
      port     => 5672,
      protocol => 'tcp',
      before   => Class['::rabbitmq'],
    }

    # Setup Corosync and Pacemaker
    class { 'corosync':
        authkey             => '/etc/puppetlabs/puppet/ssl/certs/ca.pem',
        bind_address        => $management_ip,
        cluster_name        => 'openstack_corosync_cluster',
        enable_secauth      => true,
        set_votequorum      => true,
        quorum_members      => $::easystack::config::controller_servers,
        manage_pcsd_service => true,
        rrp_mode            => 'active',
    }

    corosync::service { 'pacemaker':
        version => 1,
    }

    firewalld_service { 'Allow Corosync and pacemaker multicast':
      ensure  => present,
      service => 'high-availability',
      zone    => 'public',
      before  => Class['corosync'],
    }

    cs_property { 'pe-warn-series-max':
        value => 1000,
    }

    cs_property { 'pe-input-series-max':
        value => 1000,
    }

    cs_property { 'pe-error-series-max':
        value => 1000,
    }

    cs_property { 'cluster-recheck-interval':
        value => '5min',
    }

    if ($::is_virtual) {
        # lint:ignore:quoted_booleans
        cs_property { 'stonith-enabled':
            value => 'false',
        }
        # lint:endignore
    }

    cs_primitive { 'generic_vip':
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
    }

}
