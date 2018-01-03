# Setup Netdata
class easystack::profile::netdata (
    String $listen_ip       = ip_for_network($::easystack::config::management_network),
    Boolean $enable_backend = $::easystack::config::netdata_enable_backend,
    String $destination     = $::easystack::config::netdata_destination,
    String $data_source     = $::easystack::config::netdata_data_source,
    String $update_every    = $::easystack::config::netdata_update_every,
    String $prefix          = $::easystack::config::netdata_prefix,
    String $version         = $::easystack::config::netdata_version,
    String $base            = $::easystack::config::netdata_base,
) {
    # make sure the parameters are initialized
    include ::easystack

    class { 'netdata':
        web_bind       => $listen_ip,
        enable_backend => $enable_backend,
        destination    => $destination,
        data_source    => $data_source,
        update_every   => $update_every,
        prefix         => $prefix,
        version        => $version,
        base           => $base,
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
