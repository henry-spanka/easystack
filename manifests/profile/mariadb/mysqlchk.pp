# Bootstrap the Galera Cluster
class easystack::profile::mariadb::mysqlchk (
    String $host = ip_for_network($::easystack::config::management_network),
    String $status_password = $::easystack::config::database_status_password,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::mariadb::galera

    ::etc_services { 'mysqlchk/tcp':
        port    => '9200',
        aliases => [],
        comment => 'Mysqlcheck',
        before  => Class['galera::status'],
    }

    class { 'galera::status':
        status_password         => $status_password,
        status_user             => 'status',
        status_allow            => '%',
        port                    => '9200',
        available_when_donor    => 0,
        available_when_readonly => 0,
        status_host             => $host,
    }

    include ::firewalld

    firewalld_port { 'Allow galera status check on port 9200 tcp':
        ensure   => present,
        zone     => 'public',
        port     => 9200,
        protocol => 'tcp',
        before   => Service['xinetd'],
    }
}
