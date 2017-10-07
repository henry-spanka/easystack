# Setup Public VIP Resource
class easystack::profile::corosync::public_vip (
    String $public_interface = $::easystack::config::public_interface,
    String $public_mgmt_vlan = $::easystack::config::public_mgmt_vlan,
    String $public_vip       = $::easystack::config::public_vip,
    String $public_vip_cidr  = $::easystack::config::public_vip_cidr,
    String $public_vip_gw    = $::easystack::config::public_vip_gw,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync

    cs_primitive { 'public_vip':
        primitive_class => 'ocf',
        primitive_type  => 'IPaddr2',
        provided_by     => 'heartbeat',
        parameters      => {
            'ip'           => $public_vip,
            'cidr_netmask' => $public_vip_cidr,
            'nic'          => "${public_interface}.${public_mgmt_vlan}",
        },
        operations      => {
            'monitor' => {
                'interval' => '30s',
            }
        },
        require         => Anchor['easystack::corosync::setup::begin'],
        before          => Anchor['easystack::corosync::setup::end'],
    }

    cs_primitive { 'public_vip_route':
        primitive_class => 'ocf',
        primitive_type  => 'Route',
        provided_by     => 'heartbeat',
        parameters      => {
            'destination' => 'default',
            'gateway'     => $public_vip_gw,
            'source'      => $public_vip,
            'table'       => 'public_mgmt',
        },
        operations      => {
            'monitor' => {
                'interval' => '30s',
            }
        },
        require         => Anchor['easystack::corosync::setup::begin'],
        before          => Anchor['easystack::corosync::setup::end'],
    }

    cs_colocation { 'public_vip_with_route':
        primitives => ['public_vip', 'public_vip_route'],
        score      => 'INFINITY',
        require    => [
            Cs_primitive['public_vip'],
            Cs_primitive['public_vip_route'],
        ],
    }

    cs_order { 'vip_before_service':
        first   => 'public_vip',
        second  => 'public_vip_route',
        kind    => 'Mandatory',
        require => Cs_colocation['public_vip_with_route'],
    }

}
