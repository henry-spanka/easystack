# Setup Glance Service
class easystack::profile::glance (
    String $listen_ip       = ip_for_network($::easystack::config::management_network),
    Array $controller_nodes = $::easystack::config::controller_nodes,
    String $vip             = $::easystack::config::controller_vip,
    String $db_password     = $::easystack::config::database_glance_password,
    String $glance_password = $::easystack::config::keystone_glance_password,
    String $region          = $::easystack::config::keystone_region,
    Boolean $master         = false,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::firewalld

    firewalld_port { 'Allow glance api on port 9292 tcp':
        ensure   => present,
        zone     => 'public',
        port     => 9292,
        protocol => 'tcp',
        tag      => 'glance-firewall',
        before   => Service['glance-api'],
    }

    firewalld_port { 'Allow glance registry on port 9191 tcp':
        ensure   => present,
        zone     => 'public',
        port     => 9191,
        protocol => 'tcp',
        tag      => 'glance-firewall',
        before   => Service['glance-registry'],
    }

    class { '::glance': }

    # lint:ignore:duplicate_params
    glance_api_config {
        'paste_deploy/flavor': ensure => present, value => 'keystone';
        'DEFAULT/bind_host': ensure => present, value => $listen_ip;
    }
    # lint:endignore

    class { '::glance::api::db':
        database_connection => "mysql+pymysql://glance:${db_password}@${vip}/glance",
        notify              => Service['glance-api'],
    }

    $controller_nodes_ip = $controller_nodes.map |Hash $params| {
        $params[ip]
    }

    class { '::glance::api::authtoken':
        project_name        => 'services',
        project_domain_name => 'default',
        user_domain_name    => 'default',
        memcached_servers   => $controller_nodes_ip,
        username            => 'glance',
        password            => $glance_password,
        notify              => Service['glance-api'],
    }

    # lint:ignore:duplicate_params
    glance_registry_config {
        'paste_deploy/flavor': ensure => present, value => 'keystone';
        'DEFAULT/bind_host': ensure => present, value => $listen_ip;
    }
    # lint:endignore

    class { '::glance::registry::db':
        database_connection => "mysql+pymysql://glance:${db_password}@${vip}/glance",
        notify              => Service['glance-registry'],
    }

    class { '::glance::registry::authtoken':
        project_name        => 'services',
        project_domain_name => 'default',
        user_domain_name    => 'default',
        memcached_servers   => $controller_nodes_ip,
        username            => 'glance',
        password            => $glance_password,
        notify              => Service['glance-registry'],
    }

    class { 'glance::backend::file': }

    if ($master) {
        class { '::glance::keystone::auth':
            password            => $glance_password,
            auth_name           => 'glance',
            configure_endpoint  => true,
            configure_user      => true,
            configure_user_role => true,
            service_name        => 'glance',
            public_url          => "http://${vip}:9292",
            internal_url        => "http://${vip}:9292",
            admin_url           => "http://${vip}:9292",
            region              => $region,
            tenant              => 'services',
            require             => Class['::easystack::profile::keystone'],
        }

        class { '::glance::db::sync':
            before  => [
                Service['glance-api'],
                Service['glance-registry'],
            ],
            require => Class['::easystack::profile::mariadb'],
        }
    }

    service { 'glance-api':
        ensure     => 'running',
        name       => 'openstack-glance-api',
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        tag        => 'glance-service',
    }

    service { 'glance-registry':
        ensure     => 'running',
        name       => 'openstack-glance-registry',
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        tag        => 'glance-service',
    }

}
