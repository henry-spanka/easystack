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

    cinder_config {
        'DEFAULT/allowed_direct_url_schemes': value => 'cinder';
        'DEFAULT/image_upload_use_cinder_backend': value => true;
    }

    Anchor['easystack::openstack::install_1::begin']
    -> Anchor['cinder::install::begin']
    -> Anchor['cinder::install::end']
    -> Anchor['easystack::openstack::install_1::end']

    Anchor['easystack::openstack::config_1::begin']
    -> Anchor['cinder::config::begin']
    -> Anchor['cinder::config::end']
    -> Anchor['easystack::openstack::config_1::end']

    Anchor['easystack::openstack::dbsync_2::begin']
    -> Anchor['cinder::db::begin']
    -> Anchor['cinder::db::end']
    -> Anchor['cinder::dbsync::begin']
    -> Anchor['cinder::dbsync::end']
    -> Anchor['easystack::openstack::dbsync_2::end']

    Anchor['easystack::openstack::service_2::begin']
    -> Anchor['cinder::service::begin']
    -> Anchor['cinder::service::end']
    -> Anchor['easystack::openstack::service_2::end']

    Firewalld_port <|tag == 'cinder-firewall'|>
    -> Anchor['easystack::openstack::service_2::begin']

}
