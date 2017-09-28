# Setup Network for Controller
class easystack::profile::network::controller (
    String $management_network = $::easystack::config::management_network,
    String $management_interface = 'eth0',
    String $public_interface = 'eth1',
) {
    # make sure the parameters are initialized
    include easystack

    firewalld_zone { 'internal':
        ensure     => present,
        interfaces => [$management_interface],
        sources    => [$management_network],
    }

    firewalld_zone { 'public':
        ensure           => present,
        interfaces       => [$public_interface],
        purge_rich_rules => true,
        purge_services   => true,
        purge_ports      => true,
    }

}
