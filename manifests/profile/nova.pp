# Setup Nova Service
class easystack::profile::nova (
    String $listen_ip       = ip_for_network($::easystack::config::management_network),
    Array $controller_nodes = $::easystack::config::controller_nodes,
    String $vip             = $::easystack::config::controller_vip,
    String $db_password     = $::easystack::config::database_nova_password,
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

    class { 'nova':
        database_connection     => "mysql+pymysql://nova:${db_password}@${vip}/nova?charset=utf8",
        api_database_connection => "mysql+pymysql://nova:${db_password}@${vip}/nova_api?charset=utf8",
        default_transport_url   => "rabbit://${controller_nodes_hostname_auth_list}",
        image_service           => 'nova.image.glance.GlanceImageService',
        glance_api_servers      => "http://${vip}:9292",
        auth_strategy           => 'keystone',
        lock_path               => '/var/lib/nova/tmp',
        rabbit_ha_queues        => true,
        amqp_durable_queues     => true,
    }

    # lint:ignore:duplicate_params
    nova_config {
        'DEFAULT/my_ip':                              value => $listen_ip;
        'scheduler/discover_hosts_in_cells_interval': value => 300;
    }
    # lint:endignore

    Mysql_database <| |> -> Anchor['nova::db::begin']
    Mysql_user <| |> -> Anchor['nova::db::begin']
    Mysql_grant <| |> -> Anchor['nova::db::begin']

}
