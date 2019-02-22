# Setup Galera
class easystack::profile::mariadb::galera (
    Array $controller_nodes  = $::easystack::config::controller_nodes,
    String $sstuser_password = $::easystack::config::database_sstuser_password,
    Boolean $master          = false,
) {
    # make sure the parameters are initialized
    include ::easystack

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

    package { 'percona-release':
        ensure => absent,
        before => File['/etc/pki/rpm-gpg/PERCONA-PACKAGING-KEY']
    }

    file { '/etc/pki/rpm-gpg/PERCONA-PACKAGING-KEY':
        ensure => file,
        source => 'puppet:///modules/easystack/PERCONA-PACKAGING-KEY',
    }

    yumrepo { 'percona-basearch':
        baseurl     => 'http://repo.percona.com/percona/yum/release/$releasever/RPMS/$basearch',
        descr       => 'Percona Original release/$basearch YUM repository',
        includepkgs => 'percona-xtrabackup',
        enabled     => 1,
        gpgcheck    => 1,
        gpgkey      => 'file:///etc/pki/rpm-gpg/PERCONA-PACKAGING-KEY',
        require     => File['/etc/pki/rpm-gpg/PERCONA-PACKAGING-KEY'],
    }

    yumrepo { 'percona-noarch':
        baseurl     => 'http://repo.percona.com/percona/yum/release/$releasever/RPMS/noarch',
        descr       => 'Percona Original release/noarch YUM repository',
        includepkgs => 'percona-xtrabackup',
        enabled     => 1,
        gpgcheck    => 1,
        gpgkey      => 'file:///etc/pki/rpm-gpg/PERCONA-PACKAGING-KEY',
        require     => File['/etc/pki/rpm-gpg/PERCONA-PACKAGING-KEY'],
    }

    package { 'percona-xtrabackup':
        ensure  => installed,
        require => [
            Yumrepo['percona-basearch'],
            Yumrepo['percona-noarch']
        ]
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

    if ($master) {
        mysql_user { 'sstuser@localhost':
            ensure        => 'present',
            password_hash => mysql_password($sstuser_password),
        }
        -> mysql_grant { 'sstuser@localhost/*.*':
            ensure     => 'present',
            options    => ['GRANT'],
            privileges => ['RELOAD', 'LOCK TABLES', 'REPLICATION CLIENT'],
            table      => '*.*',
            user       => 'sstuser@localhost',
        }
    }

    include ::firewalld

    firewalld_port { 'Allow galera replication on port 4444 tcp':
        ensure   => present,
        zone     => 'internal',
        port     => 4444,
        protocol => 'tcp',
        tag      => 'mysql-firewall',
    }

    firewalld_port { 'Allow galera replication on port 4567 tcp':
        ensure   => present,
        zone     => 'internal',
        port     => 4567,
        protocol => 'tcp',
        tag      => 'mysql-firewall',
    }

    firewalld_port { 'Allow galera replication on port 4568 tcp':
        ensure   => present,
        zone     => 'internal',
        port     => 4568,
        protocol => 'tcp',
        tag      => 'mysql-firewall',
    }

    firewalld_port { 'Allow galera replication on port 4567 udp':
        ensure   => present,
        zone     => 'internal',
        port     => 4567,
        protocol => 'udp',
        tag      => 'mysql-firewall',
    }

    # Dependencies definition
    Package['galera']
    -> Package['rsync']
    -> Package['socat']
    -> Package['nmap']
    -> Package['percona-xtrabackup']
    -> Class['::mysql::server']

}
