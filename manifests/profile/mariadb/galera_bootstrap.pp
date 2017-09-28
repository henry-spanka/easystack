# Bootstrap the Galera Cluster
class easystack::profile::mariadb::galera_bootstrap {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::mariadb::galera

    exec { 'bootstrap_galera_cluster':
        command  => '/usr/bin/galera_new_cluster',
        unless   => [
            'test -f /root/galera_bootstrapped',
            'systemctl is-active mariadb.service | grep -w active',
        ],
        require  => Anchor['easystack::database::install::end'],
        before   => Anchor['easystack::database::service::begin'],
        notify   => Exec['wait_for_mysql_wsrep_sync'],
        provider => shell,
        path     => '/usr/bin:/bin:/usr/sbin:/sbin'
    }

    file { '/root/galera_bootstrapped':
        ensure  => file,
        source  => 'puppet:///modules/easystack/galera_bootstrapped',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Exec['bootstrap_galera_cluster'],
    }

    Anchor['easystack::database::bootstrap::begin']
    -> Class['easystack::profile::mariadb::galera_bootstrap']
    ~> Anchor['easystack::database::bootstrap::end']

}
