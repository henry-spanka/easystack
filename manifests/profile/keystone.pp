# Setup Keystone Service
class easystack::profile::keystone (
    String $listen_ip      = ip_for_network($::easystack::config::management_network),
    String $vip            = $::easystack::config::controller_vip,
    String $admin_token    = $::easystack::config::keystone_admin_token,
    String $db_password    = $::easystack::config::database_keystone_password,
    String $admin_email    = $::easystack::config::keystone_admin_email,
    String $admin_password = $::easystack::config::keystone_admin_password,
    String $region         = $::easystack::config::keystone_region,
    Boolean $master        = false,
    Hash $fernet_keys      = $::easystack::config::keystone_fernet_keys,
) {
    # make sure the parameters are initialized
    include ::easystack

    include apache

    class { 'keystone::wsgi::apache':
        servername => $::fqdn,
        ssl        => false,
        bind_host  => $listen_ip
    }

    selinux::port { 'allow-keystone-httpd-5000':
        seltype  => 'http_port_t',
        port     => 5000,
        protocol => 'tcp',
        before   => Class['apache::service'],
    }
    selinux::port { 'allow-keystone-httpd-35357':
        seltype  => 'http_port_t',
        port     => 35357,
        protocol => 'tcp',
        before   => Class['apache::service'],
    }
    selinux::boolean { 'httpd_can_network_connect_db':
        ensure => 'on',
        before => Class['apache::service'],
    }

    include ::firewalld

    firewalld_port { 'Allow keystone public and internal endpoint on port 5000 tcp':
      ensure   => present,
      zone     => 'public',
      port     => 5000,
      protocol => 'tcp',
      tag      => 'keystone-firewall',
    }

    firewalld_port { 'Allow keystone admin endpoint on port 35357 tcp':
      ensure   => present,
      zone     => 'public',
      port     => 35357,
      protocol => 'tcp',
      tag      => 'keystone-firewall',
    }

    # Dependencies definition
    Firewalld_port <|tag == 'keystone-firewall'|> -> Class['apache::service']
    Package['openstack-keystone'] -> Class['apache::service']

    class { 'keystone':
        catalog_type        => 'sql',
        admin_token         => $admin_token,
        database_connection => "mysql+pymysql://keystone:${db_password}@${vip}/keystone",
        token_provider      => 'fernet',
        service_name        => 'httpd',
        require             => Class['::easystack::profile::mariadb'],
        public_bind_host    => $listen_ip,
        admin_bind_host     => $listen_ip,
        public_endpoint     => "http://${vip}:5000",
        admin_endpoint      => "http://${vip}:35357",
        sync_db             => $master,
        enable_fernet_setup => true,
        fernet_keys         => $fernet_keys,

    }

    if ($master) {
        # Installs the service user endpoint.
        class { 'keystone::endpoint':
            public_url   => "http://${vip}:5000",
            admin_url    => "http://${vip}:35357",
            internal_url => "http://${vip}:5000",
            region       => $region,
            #   If the version is set to the empty string (''), then it won't be
            #   used. This is the expected behaviour since Keystone V3 handles API versions
            #   from the context.
            version      => '',
            require      => [
                Class['apache::service'],
                Class['::easystack::profile::mariadb'],
            ],
            before       => File['/root/openrc'],
        }

        class { 'keystone::roles::admin':
            email    => $admin_email,
            password => $admin_password,
            require  => [
                Class['apache::service'],
                Class['::easystack::profile::mariadb'],
                Class['keystone::endpoint'],
            ],
            before   => File['/root/openrc'],
        }

        keystone_role { 'user':
            ensure  => present,
            require => [
                Class['keystone::endpoint'],
                Class['keystone::roles::admin'],
                Class['keystone::endpoint'],
            ],
            before  => File['/root/openrc'],
        }

        # Remove the admin_token_auth paste pipeline.
        # After the first puppet run this requires setting keystone v3
        # admin credentials via /root/openrc or as environment variables.
        include keystone::disable_admin_token_auth
    } else {
        # Remove the admin_token_auth paste pipeline.
        # After the first puppet run this requires setting keystone v3
        # admin credentials via /root/openrc or as environment variables.
        Ini_subsetting {
            notify => Exec['restart_keystone'],
        }

        ini_subsetting { 'public_api/admin_token_auth':
            ensure     => absent,
            path       => '/etc/keystone/keystone-paste.ini',
            section    => 'pipeline:public_api',
            setting    => 'pipeline',
            subsetting => 'admin_token_auth',
            before     => File['/root/openrc'],
        }
        ini_subsetting { 'admin_api/admin_token_auth':
            ensure     => absent,
            path       => '/etc/keystone/keystone-paste.ini',
            section    => 'pipeline:admin_api',
            setting    => 'pipeline',
            subsetting => 'admin_token_auth',
            before     => File['/root/openrc'],
        }
        ini_subsetting { 'api_v3/admin_token_auth':
            ensure     => absent,
            path       => '/etc/keystone/keystone-paste.ini',
            section    => 'pipeline:api_v3',
            setting    => 'pipeline',
            subsetting => 'admin_token_auth',
            before     => File['/root/openrc'],
        }
    }

    file { '/root/openrc':
        ensure    => file,
        content   => epp(
            'easystack/keystone/openrc.epp',
            {
                'auth_url'      => "http://${vip}:35357/v3",
                'auth_password' => $admin_password,
            }
        ),
        show_diff => false,
        owner     => 'root',
        group     => 'root',
        mode      => '0600', # Only root should be able to read the credentials
    }

}
