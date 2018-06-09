# Setup Network for Compute with Ceph Bonding
class easystack::profile::network::compute_ceph (
    String $management_network   = $::easystack::config::management_network,
    Array $admin_networks        = $::easystack::config::admin_networks,
    String $management_interface = $::easystack::config::management_interface,
    String $public_interface     = $::easystack::config::public_interface,
    String $ceph_public_vlan     = $::easystack::config::ceph_public_vlan,
) {
    # make sure the parameters are initialized
    include easystack

    if ($management_interface != $public_interface) {
        fail('Management Interface must equal public interface if bonding is used')
    }

    $bond_iface = $management_interface

    # Bond Interface

    file_line { "${bond_iface} disable NetworkManager":
        ensure => 'present',
        path   => "/etc/sysconfig/network-scripts/ifcfg-${bond_iface}",
        line   => 'NM_CONTROLLED=no',
        match  => '^NM_CONTROLLED=*',
        notify => Exec['network_restart'],
    }

    file_line { "${bond_iface} set onboot":
        ensure => 'present',
        path   => "/etc/sysconfig/network-scripts/ifcfg-${bond_iface}",
        line   => 'ONBOOT=yes',
        match  => '^ONBOOT=*',
        notify => Exec['network_restart'],
    }

    file_line { "${bond_iface} set bootproto":
        ensure => 'present',
        path   => "/etc/sysconfig/network-scripts/ifcfg-${bond_iface}",
        line   => 'BOOTPROTO=none',
        match  => '^BOOTPROTO=*',
        notify => Exec['network_restart'],
    }

    file_line { "${bond_iface} zone=public":
        ensure => 'present',
        path   => "/etc/sysconfig/network-scripts/ifcfg-${bond_iface}",
        line   => 'ZONE=public',
        match  => '^ZONE=*',
        notify => Exec['network_restart'],
    }

    ## Ceph Interface

    $ceph_public_iface = "vlan${ceph_public_vlan}";

    file_line { "${$ceph_public_iface} disable NetworkManager":
        ensure => 'present',
        path   => "/etc/sysconfig/network-scripts/ifcfg-${ceph_public_iface}",
        line   => 'NM_CONTROLLED=no',
        match  => '^NM_CONTROLLED=*',
        notify => Exec['network_restart'],
    }

    file_line { "${$ceph_public_iface} set onboot":
        ensure => 'present',
        path   => "/etc/sysconfig/network-scripts/ifcfg-${ceph_public_iface}",
        line   => 'ONBOOT=yes',
        match  => '^ONBOOT=*',
        notify => Exec['network_restart'],
    }

    file_line { "${$ceph_public_iface} zone=ceph_public":
        ensure => 'present',
        path   => "/etc/sysconfig/network-scripts/ifcfg-${ceph_public_iface}",
        line   => 'ZONE=ceph_public',
        notify => Exec['network_restart'],
    }

    service { 'NetworkManager':
        ensure => 'stopped',
        enable => false,
        before => Exec['network_restart'],
    }

    contain network

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

    firewalld_zone { 'public':
        ensure           => present,
        interfaces       => [$bond_iface],
        purge_rich_rules => true,
        purge_services   => true,
        purge_ports      => true,
    }

    firewalld_zone { 'ceph_public':
        ensure           => present,
        interfaces       => [$ceph_public_iface],
        purge_rich_rules => true,
        purge_services   => true,
        purge_ports      => true,
        require          => Exec['network_restart'],
    }

    # RP Filter drops DHCPv6 requests from VMs
    file_line { 'disable ipv6_rpfilter':
        ensure => 'present',
        path   => '/etc/firewalld/firewalld.conf',
        line   => 'IPv6_rpfilter=no',
        match  => '^IPv6_rpfilter=*',
        notify => Service['firewalld'],
    }

    Anchor['easystack::network::begin']
    -> Class['easystack::profile::network::compute_ceph']
    -> Anchor['easystack::network::end']

}
