# Setup Glance Registry
class easystack::profile::glance::registry (
    String $listen_ip     = ip_for_network($::easystack::config::management_network),
    String $vip           = $::easystack::config::controller_vip,
    String $db_password   = $::easystack::config::database_glance_password,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::glance

    class { '::glance::registry':
        bind_host           => $listen_ip,
        enable_v1_registry  => false,
        pipeline            => 'keystone',
        database_connection => "mysql+pymysql://glance:${db_password}@${vip}/glance",
        auth_strategy       => 'keystone',
    }

    include ::firewalld

    firewalld_port { 'Allow glance registry on port 9191 tcp':
        ensure   => present,
        zone     => 'public',
        port     => 9191,
        protocol => 'tcp',
        tag      => 'glance-firewall',
        before   => Service['glance-registry'],
    }

}
