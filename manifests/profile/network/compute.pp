# Setup Network for Compute
class easystack::profile::network::compute (
    String $management_network = $::easystack::config::management_network,
    String $management_interface = $::easystack::config::management_interface,
    String $public_interface = $::easystack::config::public_interface,
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

    file_line { "${management_interface} zone=drop":
        ensure => 'present',
        path   => "/etc/sysconfig/network-scripts/ifcfg-${management_interface}",
        line   => 'ZONE=drop',
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

    file_line { "${public_interface} zone=public":
        ensure => 'present',
        path   => "/etc/sysconfig/network-scripts/ifcfg-${public_interface}",
        line   => 'ZONE=public',
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

    # On physical servers spanning tree will block the port for a few seconds
    exec { 'wait_for_network_ready':
        command     => 'sleep 30',
        path        => '/bin:/usr/bin',
        refreshonly => true,
        subscribe   => Service['network'],
    }

    firewalld_zone { 'internal':
        ensure     => present,
        sources    => [$management_network],
    }

    firewalld_zone { 'drop':
        ensure     => present,
        interfaces => [$management_interface],
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
