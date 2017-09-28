# Setup Neutron Service
class easystack::profile::neutron (
    String $listen_ip        = ip_for_network($::easystack::config::management_network),
    Array $controller_nodes  = $::easystack::config::controller_nodes,
    String $rabbit_password  = $::easystack::config::rabbitmq_user_openstack_password,
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

    class { '::neutron':
        enabled                 => true,
        bind_host               => $listen_ip,
        default_transport_url   => "rabbit://${controller_nodes_hostname_auth_list}",
        debug                   => false,
        auth_strategy           => 'keystone',
        lock_path               => '/var/lib/neutron/tmp',
        use_ssl                 => false,
        core_plugin             => 'ml2',
        service_plugins         => [],
        allow_overlapping_ips   => true,
        rabbit_ha_queues        => true,
        amqp_durable_queues     => true,
        dhcp_agents_per_network => '3',
    }

    Anchor['easystack::openstack::install_1::begin']
    -> Anchor['neutron::install::begin']
    -> Anchor['neutron::install::end']
    -> Anchor['easystack::openstack::install_1::end']

    Anchor['easystack::openstack::config_1::begin']
    -> Anchor['neutron::config::begin']
    -> Anchor['neutron::config::end']
    -> Anchor['easystack::openstack::config_1::end']

    Anchor['easystack::openstack::dbsync_2::begin']
    -> Anchor['neutron::db::begin']
    -> Anchor['neutron::db::end']
    -> Anchor['neutron::dbsync::begin']
    -> Anchor['neutron::dbsync::end']
    -> Anchor['easystack::openstack::dbsync_2::end']

    Anchor['easystack::openstack::service_2::begin']
    -> Anchor['neutron::service::begin']
    -> Anchor['neutron::service::end']
    -> Anchor['easystack::openstack::service_2::end']

    Firewalld_port <|tag == 'neutron-firewall'|>
    -> Anchor['easystack::openstack::service_2::begin']

}
