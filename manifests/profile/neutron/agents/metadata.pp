# Setup Neutron Metadata Agent
class easystack::profile::neutron::agents::metadata (
    String $vip     = $::easystack::config::controller_vip,
    String $shared_secret = $::easystack::config::neutron_metadata_shared_secret,
    Boolean $manage       = false,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::neutron

    class { '::neutron::agents::metadata':
        metadata_ip    => $vip,
        shared_secret  => $shared_secret,
        manage_service => $manage,
        enabled        => $manage,
    }

}
