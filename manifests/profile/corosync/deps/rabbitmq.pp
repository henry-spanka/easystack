# Define RabbitMQ Relationships when managed through pacemaker
class easystack::profile::corosync::deps::rabbitmq {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync
    include ::easystack::profile::rabbitmq

    exec { 'wait-for-rabbitmq-running':
        command   => 'systemctl is-active rabbitmq-server.service | grep active',
        unless    => 'systemctl is-active rabbitmq-server.service | grep active',
        tries     => '3',
        try_sleep => '10',
        path      => '/bin:/usr/bin',
        require   => Class['::rabbitmq::config'],
        before    => Class['::rabbitmq::service'],
    }

    Class['::rabbitmq::config'] -> Exec['reauthenticate-across-all-nodes']
    Exec['reauthenticate-across-all-nodes'] -> Exec['wait-for-rabbitmq-running']

    Exec['wait-for-rabbitmq-running'] -> Rabbitmq_user <| |>
    Exec['wait-for-rabbitmq-running'] -> Rabbitmq_user_permissions <| |>
    Exec['wait-for-rabbitmq-running'] -> Rabbitmq_policy <| |>

    Exec['wait-for-haproxy-running'] -> Exec['wait-for-rabbitmq-running']

}
