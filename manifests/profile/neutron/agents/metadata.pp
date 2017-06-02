# Setup Neutron Metadata Agent
class easystack::profile::neutron::agents::metadata (
    String $listen_ip     = ip_for_network($::easystack::config::management_network),
    String $shared_secret = $::easystack::config::neutron_metadata_shared_secret
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::neutron

    class { '::neutron::agents::metadata':
        metadata_ip   => ip_for_network($::easystack::config::management_network),
        shared_secret => $::easystack::config::neutron_metadata_shared_secret,
    }

}
