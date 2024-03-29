# Setup Neutron Server
class easystack::profile::neutron::server (
    String $vip              = $::easystack::config::controller_vip,
    String $admin_endpoint   = $::easystack::config::admin_endpoint,
    String $db_password      = $::easystack::config::database_neutron_password,
    String $neutron_password = $::easystack::config::keystone_neutron_password,
    String $nova_password    = $::easystack::config::keystone_nova_password,
    String $region           = $::easystack::config::keystone_region,
    Boolean $sync_db         = false
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::neutron

    include ::firewalld

    firewalld_port { 'Allow neutron api on port 9696 tcp - zone=internal':
        ensure   => present,
        zone     => 'internal',
        port     => 9696,
        protocol => 'tcp',
        tag      => 'neutron-firewall',
        before   => Service['neutron-server'],
    }

    firewalld_port { 'Allow neutron api on port 9696 tcp - zone=public_mgmt':
        ensure   => present,
        zone     => 'public_mgmt',
        port     => 9696,
        protocol => 'tcp',
        tag      => 'neutron-firewall',
        before   => Service['neutron-server'],
    }

    class { '::neutron::server':
        database_connection              => "mysql+pymysql://neutron:${db_password}@${vip}/neutron?charset=utf8",
        auth_strategy                    => 'keystone',
        l3_ha                            => true,
        allow_automatic_l3agent_failover => true,
        max_l3_agents_per_router         => '2',
        sync_db                          => $sync_db,
        enable_proxy_headers_parsing     => true,
    }

    class { '::neutron::server::notifications':
        username                           => 'nova',
        password                           => $nova_password,
        notify_nova_on_port_status_changes => true,
        notify_nova_on_port_data_changes   => true,
        project_name                       => 'services',
        project_domain_name                => 'default',
        user_domain_name                   => 'default',
        auth_type                          => 'password',
        auth_url                           => "https://${admin_endpoint}:35357",
        region_name                        => $region,
    }

}
