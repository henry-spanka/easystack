# Setup Cinder API
class easystack::profile::cinder::api (
    String $vip       = $::easystack::config::controller_vip,
    String $listen_ip = ip_for_network($::easystack::config::management_network),
    Boolean $sync_db  = false,
    String $region    = $::easystack::config::keystone_region,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::cinder

    class { '::cinder::api':
        enabled                    => true,
        manage_service             => true,
        os_region_name             => $region,
        keymgr_encryption_auth_url => "http://${vip}:5000/v3",
        bind_host                  => $listen_ip,
        sync_db                    => $sync_db,
        public_endpoint            => "http://${vip}:35357",
        auth_strategy              => 'keystone',
    }

    include ::firewalld

    firewalld_port { 'Allow cinder api on port 8776 tcp':
        ensure   => present,
        zone     => 'internal',
        port     => 8776,
        protocol => 'tcp',
        tag      => 'cinder-firewall',
        before   => Service['cinder-api'],
    }

}
