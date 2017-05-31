# Setup MariaDB
class easystack::profile::mariadb (
    String $listen_ip        = ip_for_network($::easystack::config::management_network),
    Array $controller_nodes  = $::easystack::config::controller_nodes,
    String $root_password    = $::easystack::config::database_root_password,
    String $sstuser_password = $::easystack::config::database_sstuser_password,
    Boolean $master          = false,
) {
    # make sure the parameters are initialized
    include ::easystack

    # Setup MariaDB repo
    include ::easystack::profile::mariadb::repo

    $controller_nodes_fqdn = $controller_nodes.map |Hash $params| {
        $params[fqdn]
    }

    $controller_nodes_fqdn_list = join($controller_nodes_fqdn, ',')

    # Setup Controller SQL databases
    class { '::mysql::server':
        package_name            => 'MariaDB-server',
        root_password           => $root_password,
        remove_default_accounts => true,
        create_root_my_cnf      => true,
        create_root_user        => $master,
        override_options        => {
            'mysqld' => {
                'bind-address'                   => $listen_ip,
                'default-storage-engine'         => 'innodb',
                'innodb_file_per_table'          => true,
                'max_connections'                => 4096,
                'collation-server'               => 'utf8_general_ci',
                'character-set-server'           => 'utf8',
                'wsrep_node_address'             => $listen_ip,
                'wsrep_provider'                 => '/usr/lib64/galera/libgalera_smm.so',
                'wsrep_cluster_name'             => 'openstack_galera_cluster',
                'wsrep_cluster_address'          => "gcomm://${controller_nodes_fqdn_list}",
                'wsrep_slave_threads'            => '8',
                'wsrep_sst_method'               => 'xtrabackup-v2',
                'wsrep_sst_auth'                 => "sstuser:${sstuser_password}",
                'binlog_format'                  => 'ROW',
                'innodb_locks_unsafe_for_binlog' => '1',
                'innodb_autoinc_lock_mode'       => '2',
                'query_cache_size'               => '0',
                'query_cache_type'               => '0',
                'wsrep_node_incoming_address'    => $listen_ip,
                'wsrep_sst_receive_address'      => $listen_ip,
                'wsrep_on'                       => 'ON',
            }
        }
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

    class { '::easystack::profile::mariadb::galera':
        controller_nodes => $controller_nodes,
    }

    include ::firewalld

    firewalld_service { 'Allow mysql':
        ensure  => present,
        service => 'mysql',
        zone    => 'public',
        tag     => 'mysql-firewall',
    }

    # Dependencies definition
    Class['::easystack::profile::mariadb::repo']
    -> Class['::mysql::server']

    Firewalld_port <|tag == 'mysql-firewall'|>
    -> Firewalld_service <|tag == 'mysql-firewall'|>
    -> Class['mysql::server::installdb']
}
