# Setup VIP Resource
class easystack::profile::corosync::vip (
    String $vip             = $::easystack::config::controller_vip,
    String $management_network = $::easystack::config::management_network,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync

    $cidr_netmask = split($management_network, '/')[1]

    cs_primitive { 'vip':
        primitive_class => 'ocf',
        primitive_type  => 'IPaddr2',
        provided_by     => 'heartbeat',
        parameters      => {
            'ip'           => $vip,
            'cidr_netmask' => $cidr_netmask,
        },
        operations      => {
            'monitor' => {
                'interval' => '30s',
            }
        },
        require         => Class['::easystack::profile::corosync'],
    }

}
