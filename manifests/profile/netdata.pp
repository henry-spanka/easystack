# Setup Netdata
class easystack::profile::netdata (
    String $listen_ip = ip_for_network($::easystack::config::management_network),
) {
    # make sure the parameters are initialized
    include ::easystack

    class { 'netdata':
        web_bind => $listen_ip,
    }

    firewalld_port { 'Allow netdata web access for admin - zone=admin':
        ensure   => present,
        zone     => 'admin',
        port     => 19999,
        protocol => 'tcp',
        tag      => 'netdata-firewall',
    }

    Firewalld_port <|tag == 'netdata-firewall'|>
    -> Anchor['netdata::service::begin']


    Anchor['easystack::netdata::begin']
    -> Class['easystack::profile::netdata']
    -> Anchor['easystack::netdata::end']
}
