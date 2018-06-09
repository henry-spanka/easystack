# Setup Network for Controller
class easystack::profile::network::controller_ceph (
    String $management_network = $::easystack::config::management_network,
    Array $admin_networks = $::easystack::config::admin_networks,
    String $management_interface = $::easystack::config::management_interface,
    String $public_interface = $::easystack::config::public_interface,
    String $public_mgmt_vlan = $::easystack::config::public_mgmt_vlan,
    String $public_vlan = $::easystack::config::public_vlan,
    String $public_vip = $::easystack::config::public_vip,
    String $public_vip_cidr = $::easystack::config::public_vip_cidr,
    String $public_vip_gw = $::easystack::config::public_vip_gw,
    String $ceph_public_vlan = $::easystack::config::ceph_public_vlan,
) {
    # make sure the parameters are initialized
    include easystack

    if ($management_interface == $public_interface) {
        fail('Management Interface must not be equal public interface')
    }

    file_line { "${management_interface} disable NetworkManager":
        ensure => 'present',
        path   => "/etc/sysconfig/network-scripts/ifcfg-${management_interface}",
        line   => 'NM_CONTROLLED=no',
        match  => '^NM_CONTROLLED=*',
        notify => Exec['network_restart'],
    }

    file_line { "${management_interface} set onboot":
        ensure => 'present',
        path   => "/etc/sysconfig/network-scripts/ifcfg-${management_interface}",
        line   => 'ONBOOT=yes',
        match  => '^ONBOOT=*',
        notify => Exec['network_restart'],
    }

    file_line { "${management_interface} zone=drop":
        ensure => 'present',
        path   => "/etc/sysconfig/network-scripts/ifcfg-${management_interface}",
        line   => 'ZONE=drop',
        match  => '^ZONE=*',
        notify => Exec['network_restart'],
    }

    file_line { "${public_interface} disable NetworkManager":
        ensure => 'present',
        path   => "/etc/sysconfig/network-scripts/ifcfg-${public_interface}",
        line   => 'NM_CONTROLLED=no',
        match  => '^NM_CONTROLLED=*',
        notify => Exec['network_restart'],
    }

    file_line { "${public_interface} set bootproto":
        ensure => 'present',
        path   => "/etc/sysconfig/network-scripts/ifcfg-${public_interface}",
        line   => 'BOOTPROTO=none',
        match  => '^BOOTPROTO=*',
        notify => Exec['network_restart'],
    }

    file_line { "${public_interface} set onboot":
        ensure => 'present',
        path   => "/etc/sysconfig/network-scripts/ifcfg-${public_interface}",
        line   => 'ONBOOT=yes',
        match  => '^ONBOOT=*',
        notify => Exec['network_restart'],
    }

    contain network

    network::interface { "${public_interface}.${public_mgmt_vlan}":
        vlan => 'yes',
        zone => 'public_mgmt',
    }

    network::interface { "${public_interface}.${public_vlan}":
        vlan => 'yes',
        zone => 'public',
    }

    $ceph_public_iface = "vlan${ceph_public_vlan}";

    # Ceph Public Interface
    file_line { "${ceph_public_iface} disable NetworkManager":
        ensure => 'present',
        path   => "/etc/sysconfig/network-scripts/ifcfg-${ceph_public_iface}",
        line   => 'NM_CONTROLLED=no',
        match  => '^NM_CONTROLLED=*',
        notify => Exec['network_restart'],
    }

    file_line { "${ceph_public_iface} set onboot":
        ensure => 'present',
        path   => "/etc/sysconfig/network-scripts/ifcfg-${ceph_public_iface}",
        line   => 'ONBOOT=yes',
        match  => '^ONBOOT=*',
        notify => Exec['network_restart'],
    }

    file_line { "${ceph_public_iface} set bootproto":
        ensure => 'present',
        path   => "/etc/sysconfig/network-scripts/ifcfg-${ceph_public_iface}",
        line   => 'BOOTPROTO=none',
        match  => '^BOOTPROTO=*',
        notify => Exec['network_restart'],
    }

    file_line { "${ceph_public_iface} zone=ceph_public":
        ensure => 'present',
        path   => "/etc/sysconfig/network-scripts/ifcfg-${ceph_public_iface}",
        line   => 'ZONE=ceph_public',
        match  => '^ZONE=*',
        notify => Exec['network_restart'],
    }

    network::routing_table { 'public_mgmt':
        table_id => '200',
        before   => Exec['network_restart'],
    }

    network::rule { "${public_interface}.${public_mgmt_vlan}":
        iprule => ["from ${public_vip}/32 lookup public_mgmt"],
    }

    service { 'NetworkManager':
        ensure => 'stopped',
        enable => false,
        before => Exec['network_restart'],
    }

    # On physical servers spanning tree will block the port for a few seconds
    exec { 'wait_for_network_ready':
        command     => 'sleep 30',
        path        => '/bin:/usr/bin',
        refreshonly => true,
        subscribe   => Exec['network_restart'],
    }

    firewalld_zone { 'internal':
        ensure  => present,
        sources => [$management_network],
        require => Exec['network_restart'],
    }

    firewalld_zone { 'admin':
        ensure           => present,
        sources          => $admin_networks,
        target           => 'default',
        purge_rich_rules => true,
        purge_services   => true,
        purge_ports      => true,
        require          => Exec['network_restart'],
    }

    firewalld_service { 'Allow admin ssh':
        ensure  => present,
        service => 'ssh',
        zone    => 'admin',
        tag     => 'admin-firewall',
    }

    firewalld_zone { 'drop':
        ensure     => present,
        interfaces => [$management_interface],
        require    => Exec['network_restart'],
    }

    firewalld_zone { 'public':
        ensure           => present,
        interfaces       => ["${public_interface}.${public_vlan}"],
        purge_rich_rules => true,
        purge_services   => true,
        purge_ports      => true,
        require          => Exec['network_restart'],
    }

    firewalld_zone { 'public_mgmt':
        ensure           => present,
        interfaces       => ["${public_interface}.${public_mgmt_vlan}"],
        purge_rich_rules => true,
        purge_services   => true,
        purge_ports      => true,
        require          => Exec['network_restart'],
    }

    firewalld_zone { 'ceph_public':
        ensure           => present,
        interfaces       => [$ceph_public_iface],
        purge_rich_rules => true,
        purge_services   => true,
        purge_ports      => true,
        require          => Exec['network_restart'],
    }

    Anchor['easystack::network::begin']
    -> Class['easystack::profile::network::controller_ceph']
    -> Anchor['easystack::network::end']

}
