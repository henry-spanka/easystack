# Setup Cinder Service
class easystack::profile::cinder (
    Array $controller_nodes = $::easystack::config::controller_nodes,
    String $vip             = $::easystack::config::controller_vip,
    String $db_password     = $::easystack::config::database_cinder_password,
    String $rabbit_password = $::easystack::config::rabbitmq_user_openstack_password,
) {
    # make sure the parameters are initialized
    include ::easystack

    # RabbitMQ does not like FQDNs, therefore we need to connect
    # with only the hostnames
    $controller_nodes_hostname = $controller_nodes.map |Hash $params| {
        split($params[fqdn], '\.')[0]
    }

    $controller_nodes_hostname_auth = $controller_nodes_hostname.map |String $hostname| {
        "openstack:${rabbit_password}@${hostname}:5672"
    }

    $controller_nodes_hostname_auth_list = join($controller_nodes_hostname_auth, ',')

    class { '::cinder':
        database_connection   => "mysql+pymysql://cinder:${db_password}@${vip}/cinder",
        default_transport_url => "rabbit://${controller_nodes_hostname_auth_list}",
        rpc_backend           => 'rabbit',
        rabbit_ha_queues      => true,
        amqp_durable_queues   => true,
    }

    Mysql_database <| |> -> Anchor['cinder::dbsync::begin']
    Mysql_user <| |> -> Anchor['cinder::dbsync::begin']
    Mysql_grant <| |> -> Anchor['cinder::dbsync::begin']
}
