# Setup Nova Service
class easystack::profile::nova (
    String $listen_ip             = ip_for_network($::easystack::config::management_network),
    Array $controller_nodes       = $::easystack::config::controller_nodes,
    String $vip                   = $::easystack::config::controller_vip,
    String $public_endpoint       = $::easystack::config::public_endpoint,
    String $db_password           = $::easystack::config::database_nova_password,
    String $rabbit_password       = $::easystack::config::rabbitmq_user_openstack_password,
    String $cpu_allocation_ratio  = $::easystack::config::cpu_allocation_ratio,
    String $ram_allocation_ratio  = $::easystack::config::ram_allocation_ratio,
    String $disk_allocation_ratio = $::easystack::config::disk_allocation_ratio,
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
        glance_api_servers      => "https://${public_endpoint}:9292",
        auth_strategy           => 'keystone',
        lock_path               => '/var/lib/nova/tmp',
        rabbit_ha_queues        => true,
        amqp_durable_queues     => true,
        cpu_allocation_ratio    => $cpu_allocation_ratio,
        ram_allocation_ratio    => $ram_allocation_ratio,
        disk_allocation_ratio   => $disk_allocation_ratio,
        upgrade_level_compute   => 'auto',
    }

    # lint:ignore:duplicate_params
    nova_config {
        'DEFAULT/my_ip': value => $listen_ip;
    }
    # lint:endignore

    Anchor['easystack::openstack::install_1::begin']
    -> Anchor['nova::install::begin']
    -> Anchor['nova::install::end']
    -> Anchor['easystack::openstack::install_1::end']

    Anchor['easystack::openstack::config_1::begin']
    -> Anchor['nova::config::begin']
    -> Anchor['nova::config::end']
    -> Anchor['easystack::openstack::config_1::end']

    Anchor['easystack::openstack::dbsync_1::begin']
    -> Anchor['nova::db::begin']
    -> Anchor['nova::db::end']
    -> Anchor['nova::dbsync::begin']
    -> Anchor['nova::dbsync::end']
    -> Anchor['easystack::openstack::dbsync_1::end']

    Anchor['easystack::openstack::service_1::begin']
    -> Anchor['nova::service::begin']
    -> Anchor['nova::service::end']
    -> Anchor['easystack::openstack::service_1::end']

    Firewalld_port <|tag == 'nova-firewall'|>
    -> Anchor['easystack::openstack::service_1::begin']

}
