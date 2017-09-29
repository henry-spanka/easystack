# Setup Network for Compute
class easystack::profile::network::compute (
    String $management_network = $::easystack::config::management_network,
    String $management_interface = 'eth0',
    String $public_interface = 'eth1',
) {
    # make sure the parameters are initialized
    include easystack

    file_line { "${management_interface} disable NetworkManager":
        ensure => 'present',
        path   => "/etc/sysconfig/network-scripts/ifcfg-${management_interface}",
        line   => 'NM_CONTROLLED=no',
        match  => '^NM_CONTROLLED=*',
        notify => Service['network'],
    }

    file_line { "${management_interface} set onboot":
        ensure => 'present',
        path   => "/etc/sysconfig/network-scripts/ifcfg-${management_interface}",
        line   => 'ONBOOT=yes',
        match  => '^ONBOOT=*',
        notify => Service['network'],
    }

    file_line { "${public_interface} disable NetworkManager":
        ensure => 'present',
        path   => "/etc/sysconfig/network-scripts/ifcfg-${public_interface}",
        line   => 'NM_CONTROLLED=no',
        match  => '^NM_CONTROLLED=*',
        notify => Service['network'],
    }

    file_line { "${public_interface} set bootproto":
        ensure => 'present',
        path   => "/etc/sysconfig/network-scripts/ifcfg-${public_interface}",
        line   => 'BOOTPROTO=none',
        match  => '^BOOTPROTO=*',
        notify => Service['network'],
    }

    file_line { "${public_interface} set onboot":
        ensure => 'present',
        path   => "/etc/sysconfig/network-scripts/ifcfg-${public_interface}",
        line   => 'ONBOOT=yes',
        match  => '^ONBOOT=*',
        notify => Service['network'],
    }

    service { 'NetworkManager':
        ensure => 'stopped',
        enable => false,
    }

    service { 'network':
        ensure     => 'running',
        enable     => true,
        hasrestart => true,
        require    => Service['NetworkManager'],
    }

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

    Anchor['easystack::network::begin']
    -> Class['easystack::profile::network::compute']
    -> Anchor['easystack::network::end']

}
