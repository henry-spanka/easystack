# Define MariaDB Relationships when managed through pacemaker
class easystack::profile::corosync::deps::mariadb {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync
    include ::easystack::profile::mariadb

    exec { 'wait-for-mariadb-running':
        command   => 'systemctl is-active mariadb.service | grep active',
        unless    => 'systemctl is-active mariadb.service | grep active',
        tries     => '3',
        try_sleep => '10',
        path      => '/bin:/usr/bin',
        require   => Class['mysql::server::installdb'],
        before    => Class['mysql::server::service'],
    }

    Class['mysql::server::installdb'] -> Exec['reauthenticate-across-all-nodes']
    Exec['reauthenticate-across-all-nodes'] -> Exec['wait-for-mariadb-running']

    Exec['wait-for-haproxy-running'] -> Exec['wait-for-mariadb-running']

    Exec['wait-for-mariadb-running'] -> Mysql_user <| |>
    Exec['wait-for-mariadb-running'] -> Mysql_grant <| |>
    Exec['wait-for-mariadb-running'] -> Mysql_database <| |>

    anchor { 'easystack::profile::mariadb::end': }

    Mysql_user <| |> -> Anchor['easystack::profile::mariadb::end']
    Mysql_grant <| |> -> Anchor['easystack::profile::mariadb::end']
    Mysql_database <| |> -> Anchor['easystack::profile::mariadb::end']



}
