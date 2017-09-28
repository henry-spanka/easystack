# Setup RabbitMQ Service
class easystack::profile::rabbitmq (
    String $listen_ip       = ip_for_network($::easystack::config::management_network),
    Array $controller_nodes = $::easystack::config::controller_nodes,
    String $erlang_cookie   = $::easystack::config::rabbitmq_erlang_cookie,
) {
    # make sure the parameters are initialized
    include ::easystack

    # RabbitMQ does not like FQDNs, therefore we need to establish a cluster
    # with only the hostnames

    $controller_nodes_hostname = $controller_nodes.map |Hash $params| {
        split($params[fqdn], '\.')[0]
    }

    # Install and configure RabbitMQ
    class { '::rabbitmq':
        node_ip_address            => $listen_ip,
        delete_guest_user          => true,
        config_cluster             => true,
        cluster_nodes              => $controller_nodes_hostname,
        cluster_node_type          => 'disc',
        erlang_cookie              => $erlang_cookie,
        wipe_db_on_cookie_change   => true,
        cluster_partition_handling => 'pause_minority',
        service_manage             => true,
        environment_variables      => {
            'RABBITMQ_NODE_IP_ADDRESS' => $listen_ip,
            'ERL_EPMD_ADDRESS'         => $listen_ip,
        },
    }

    include ::firewalld

    firewalld_port { 'Allow rabbitmq cluster on port 4369 tcp':
        ensure   => present,
        zone     => 'public',
        port     => 4369,
        protocol => 'tcp',
        tag      => 'rabbitmq-firewall',
    }

    firewalld_port { 'Allow rabbitmq cluster on port 25672 tcp':
        ensure   => present,
        zone     => 'public',
        port     => 25672,
        protocol => 'tcp',
        tag      => 'rabbitmq-firewall',
    }

    firewalld_port { 'Allow rabbitmq on port 5672 tcp':
        ensure   => present,
        zone     => 'public',
        port     => 5672,
        protocol => 'tcp',
        tag      => 'rabbitmq-firewall',
    }

    exec { 'wait_for_rabbitmq_ready':
        command     => 'sleep 10',
        path        => '/bin:/usr/bin',
        refreshonly => true,
        subscribe   => Service['rabbitmq-server'],
        before      => Class['rabbitmq::management'],
    }

    # Dependencies definition
    Anchor['easystack::messaging::install::begin']
    -> Class['rabbitmq::install']
    -> Class['rabbitmq::config']
    ~> Anchor['easystack::messaging::install::end']

    Anchor['easystack::messaging::service::begin']
    ~> Class['rabbitmq::service']
    -> Class['rabbitmq::management']
    -> Anchor['easystack::messaging::service::end']

    Firewalld_port <|tag == 'rabbitmq-firewall'|>
    -> Anchor['easystack::messaging::service::begin']

}
