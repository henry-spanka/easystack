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

    $controller_nodes_fqdn = $::easystack::config::controller_nodes.map |Hash $params| {
        $params[fqdn]
    }

    $controller_nodes_ip = $::easystack::config::controller_nodes.map |Hash $params| {
        $params[ip]
    }

    $controller_nodes_fqdn_spaced = join($controller_nodes_fqdn, ' ')
    $controller_nodes_fqdn_list = join($controller_nodes_fqdn, ',')
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
                'bind-address'                   => $management_ip,
                'default-storage-engine'         => 'innodb',
                'innodb_file_per_table'          => true,
                'max_connections'                => 4096,
                'collation-server'               => 'utf8_general_ci',
                'character-set-server'           => 'utf8',
                'wsrep_node_address'             => $management_ip,
                'wsrep_provider'                 => '/usr/lib64/galera/libgalera_smm.so',
                'wsrep_cluster_name'             => 'openstack_galera_cluster',
                'wsrep_cluster_address'          => "gcomm://${controller_nodes_fqdn_list}",
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
        unless   => "nmap -Pn -p 4567 ${controller_nodes_fqdn_spaced} | grep -q '4567/tcp open'",
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

    ::etc_services { 'mysqlchk/tcp':
        port    => '9200',
        aliases => [],
        comment => 'Mysqlcheck',
        before  => Class['galera::status'],
    }

    class { 'galera::status':
        status_password         => $::easystack::config::database_status_password,
        status_user             => 'status',
        status_allow            => '%',
        port                    => '9200',
        available_when_donor    => 0,
        available_when_readonly => 0,
        status_host             => $management_ip,
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

    firewalld_port { 'Allow galera status check on port 9200 tcp':
      ensure   => present,
      zone     => 'public',
      port     => 9200,
      protocol => 'tcp',
      before   => Service['xinetd'],
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
    $controller_nodes_hostname = $controller_nodes_fqdn.map |String $fqdn| {
        split($fqdn, '\.')[0]
    }

    # Install and configure RabbitMQ
    class { '::rabbitmq':
        node_ip_address            => $management_ip,
        delete_guest_user          => true,
        config_cluster             => true,
        cluster_nodes              => $controller_nodes_hostname,
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
        quorum_members      => $controller_nodes_fqdn,
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

    # Setup haproxy
    class { 'haproxy':
        global_options   => {
            chroot  => '/var/lib/haproxy',
            daemon  => '',
            user    => 'haproxy',
            group   => 'haproxy',
            pidfile => '/var/run/haproxy.pid',
            maxconn => '4000',
        },
        defaults_options => {
            'log'     => 'global',
            'stats'   => 'enable',
            'option'  => [
                'redispatch',
            ],
            'retries' => '3',
            'timeout' => [
                'http-request 10s',
                'queue 1m',
                'connect 10s',
                'client 1m',
                'server 1m',
                'check 10s',
            ],
            'maxconn' => '4000',
        },
    }

    # Horizon Dashboard
    haproxy::listen { 'dashboard_cluster':
        ipaddress => $::easystack::config::controller_vip,
        ports     => '80',
        mode      => 'tcp',
        options   => {
            'option'  => [
                'tcpka',
                'httpchk',
                'tcplog',
            ],
            'balance' => 'source',
        },
    }

    $controller_master = $::easystack::config::controller_nodes.filter |Hash $params| {
        $params[master] == true
    }

    if ($controller_master == undef or length($controller_master) != 1) {
        fail('No controller master could be found')
    }

    $controller_master_fqdn = $controller_master.map |Hash $params| {
        $params[fqdn]
    }

    $controller_master_ip = $controller_master.map |Hash $params| {
        $params[ip]
    }

    $controller_nodes_slaves = $::easystack::config::controller_nodes.filter |Hash $params| {
        $params[master] == false
    }

    $controller_nodes_slaves_fqdn = $controller_nodes_slaves.map |Hash $params| {
        $params[fqdn]
    }

    $controller_nodes_slaves_ip = $controller_nodes_slaves.map |Hash $params| {
        $params[ip]
    }

    haproxy::balancermember { 'dashboard_members':
        listening_service => 'dashboard_cluster',
        ports             => '80',
        server_names      => $controller_nodes_fqdn,
        ipaddresses       => $controller_nodes_ip,
        options           => [
            'check',
            'inter 2000',
            'rise 2',
            'fall 5',
        ],
    }

    # Galera Cluster
    haproxy::listen { 'galera_cluster':
        ipaddress => $::easystack::config::controller_vip,
        ports     => '3306',
        mode      => 'tcp',
        options   => {
            'option'  => [
                'mysql-check',
            ],
            'balance' => 'source',
        },
    }

    haproxy::balancermember { 'galera_members_master':
        listening_service => 'galera_cluster',
        ports             => '3306',
        server_names      => $controller_master_fqdn,
        ipaddresses       => $controller_master_ip,
        options           => [
            'check',
            'port 9200',
            'inter 2000',
            'rise 2',
            'fall 5',
        ],
    }

    haproxy::balancermember { 'galera_members_slaves':
        listening_service => 'galera_cluster',
        ports             => '3306',
        server_names      => $controller_nodes_slaves_fqdn,
        ipaddresses       => $controller_nodes_slaves_ip,
        options           => [
            'backup',
            'check',
            'port 9200',
            'inter 2000',
            'rise 2',
            'fall 5',
        ],
    }

    # Glance API
    haproxy::listen { 'glance_api_cluster':
        ipaddress => $::easystack::config::controller_vip,
        ports     => '9292',
        mode      => 'tcp',
        options   => {
            'option'  => [
                'tcpka',
                'httpchk',
                'tcplog',
            ],
            'balance' => 'source',
        },
    }

    haproxy::balancermember { 'glance_api_members':
        listening_service => 'glance_api_cluster',
        ports             => '9292',
        server_names      => $controller_nodes_fqdn,
        ipaddresses       => $controller_nodes_ip,
        options           => [
            'check',
            'inter 2000',
            'rise 2',
            'fall 5',
        ],
    }

    # Glance Registry
    haproxy::listen { 'glance_registry_cluster':
        ipaddress => $::easystack::config::controller_vip,
        ports     => '9191',
        mode      => 'tcp',
        options   => {
            'option'  => [
                'tcpka',
                'tcplog',
            ],
            'balance' => 'source',
        },
    }

    haproxy::balancermember { 'glance_registry_members':
        listening_service => 'glance_registry_cluster',
        ports             => '9191',
        server_names      => $controller_nodes_fqdn,
        ipaddresses       => $controller_nodes_ip,
        options           => [
            'check',
            'inter 2000',
            'rise 2',
            'fall 5',
        ],
    }

    # Keystone admin
    haproxy::listen { 'keystone_admin_cluster':
        ipaddress => $::easystack::config::controller_vip,
        ports     => '35357',
        mode      => 'tcp',
        options   => {
            'option'  => [
                'tcpka',
                'httpchk',
                'tcplog',
            ],
            'balance' => 'source',
        },
    }

    haproxy::balancermember { 'keystone_admin_members':
        listening_service => 'keystone_admin_cluster',
        ports             => '35357',
        server_names      => $controller_nodes_fqdn,
        ipaddresses       => $controller_nodes_ip,
        options           => [
            'check',
            'inter 2000',
            'rise 2',
            'fall 5',
        ],
    }

    # keystone public internal
    haproxy::listen { 'keystone_public_internal_cluster':
        ipaddress => $::easystack::config::controller_vip,
        ports     => '5000',
        mode      => 'tcp',
        options   => {
            'option'  => [
                'tcpka',
                'httpchk',
                'tcplog',
            ],
            'balance' => 'source',
        },
    }

    haproxy::balancermember { 'keystone_public_internal_members':
        listening_service => 'keystone_public_internal_cluster',
        ports             => '5000',
        server_names      => $controller_nodes_fqdn,
        ipaddresses       => $controller_nodes_ip,
        options           => [
            'check',
            'inter 2000',
            'rise 2',
            'fall 5',
        ],
    }

    # Nova EC2 API
    haproxy::listen { 'nova_ec2_api_cluster':
        ipaddress => $::easystack::config::controller_vip,
        ports     => '8773',
        mode      => 'tcp',
        options   => {
            'option'  => [
                'tcpka',
                'tcplog',
            ],
            'balance' => 'source',
        },
    }

    haproxy::balancermember { 'nova_ec2_api_members':
        listening_service => 'nova_ec2_api_cluster',
        ports             => '8773',
        server_names      => $controller_nodes_fqdn,
        ipaddresses       => $controller_nodes_ip,
        options           => [
            'check',
            'inter 2000',
            'rise 2',
            'fall 5',
        ],
    }

    # Nova Compute API
    haproxy::listen { 'nova_compute_api_cluster':
        ipaddress => $::easystack::config::controller_vip,
        ports     => '8774',
        mode      => 'tcp',
        options   => {
            'option'  => [
                'tcpka',
                'httpchk',
                'tcplog',
            ],
            'balance' => 'source',
        },
    }

    haproxy::balancermember { 'nova_compute_api_members':
        listening_service => 'nova_compute_api_cluster',
        ports             => '8774',
        server_names      => $controller_nodes_fqdn,
        ipaddresses       => $controller_nodes_ip,
        options           => [
            'check',
            'inter 2000',
            'rise 2',
            'fall 5',
        ],
    }

    # Nova Metadata API
    haproxy::listen { 'nova_metadata_api_cluster':
        ipaddress => $::easystack::config::controller_vip,
        ports     => '8775',
        mode      => 'tcp',
        options   => {
            'option'  => [
                'tcpka',
                'tcplog',
            ],
            'balance' => 'source',
        },
    }

    haproxy::balancermember { 'nova_metadata_api_members':
        listening_service => 'nova_metadata_api_cluster',
        ports             => '8775',
        server_names      => $controller_nodes_fqdn,
        ipaddresses       => $controller_nodes_ip,
        options           => [
            'check',
            'inter 2000',
            'rise 2',
            'fall 5',
        ],
    }

    # Cinder API
    haproxy::listen { 'cinder_api_cluster':
        ipaddress => $::easystack::config::controller_vip,
        ports     => '8776',
        mode      => 'tcp',
        options   => {
            'option'  => [
                'tcpka',
                'httpchk',
                'tcplog',
            ],
            'balance' => 'source',
        },
    }

    haproxy::balancermember { 'cinder_api_members':
        listening_service => 'cinder_api_cluster',
        ports             => '8776',
        server_names      => $controller_nodes_fqdn,
        ipaddresses       => $controller_nodes_ip,
        options           => [
            'check',
            'inter 2000',
            'rise 2',
            'fall 5',
        ],
    }

    # Ceilometer API
    haproxy::listen { 'ceilometer_api_cluster':
        ipaddress => $::easystack::config::controller_vip,
        ports     => '8777',
        mode      => 'tcp',
        options   => {
            'option'  => [
                'tcpka',
                'tcplog',
            ],
            'balance' => 'source',
        },
    }

    haproxy::balancermember { 'ceilometer_api_members':
        listening_service => 'ceilometer_api_cluster',
        ports             => '8777',
        server_names      => $controller_nodes_fqdn,
        ipaddresses       => $controller_nodes_ip,
        options           => [
            'check',
            'inter 2000',
            'rise 2',
            'fall 5',
        ],
    }

    # Nova VNCProxy
    haproxy::listen { 'nova_vncproxy_cluster':
        ipaddress => $::easystack::config::controller_vip,
        ports     => '6080',
        mode      => 'tcp',
        options   => {
            'option'  => [
                'tcpka',
                'tcplog',
            ],
            'balance' => 'source',
        },
    }

    haproxy::balancermember { 'nova_vncproxy_members':
        listening_service => 'nova_vncproxy_cluster',
        ports             => '6080',
        server_names      => $controller_nodes_fqdn,
        ipaddresses       => $controller_nodes_ip,
        options           => [
            'check',
            'inter 2000',
            'rise 2',
            'fall 5',
        ],
    }

    # Neutron API
    haproxy::listen { 'neutron_api_cluster':
        ipaddress => $::easystack::config::controller_vip,
        ports     => '9696',
        mode      => 'tcp',
        options   => {
            'option'  => [
                'tcpka',
                'httpchk',
                'tcplog',
            ],
            'balance' => 'source',
        },
    }

    haproxy::balancermember { 'neutron_api_members':
        listening_service => 'neutron_api_cluster',
        ports             => '9696',
        server_names      => $controller_nodes_fqdn,
        ipaddresses       => $controller_nodes_ip,
        options           => [
            'check',
            'inter 2000',
            'rise 2',
            'fall 5',
        ],
    }

    sysctl::value { 'net.ipv4.ip_nonlocal_bind':
        value  => '1',
        before => Class['haproxy'],
    }

    cs_primitive { 'haproxy':
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
        first   => 'generic_vip',
        second  => 'haproxy-clone',
        kind    => 'Optional',
        require => [
            Cs_clone['haproxy-clone'],
            Cs_primitive['generic_vip'],
        ],
    }

    cs_colocation { 'vip_with_haproxy':
        primitives => ['generic_vip', 'haproxy-clone'],
        require    => Cs_order['vip_before_haproxy'],
    }

}
