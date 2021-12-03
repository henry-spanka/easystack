# Setup Network for Compute
class easystack::profile::network::compute (
    String $management_network = $::easystack::config::management_network,
    Array $admin_networks = $::easystack::config::admin_networks,
    String $management_interface = $::easystack::config::management_interface,
    String $public_interface = $::easystack::config::public_interface,
) {
    # make sure the parameters are initialized
    include easystack

    if $::osfamily == "RedHat" {
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
            notify => Exec['network_restart'],
        }

        file_line { "${management_interface} set MTU=9000":
            ensure => 'present',
            path   => "/etc/sysconfig/network-scripts/ifcfg-${management_interface}",
            line   => 'MTU=9000',
            match  => '^MTU=*',
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

        file_line { "${public_interface} zone=public":
            ensure => 'present',
            path   => "/etc/sysconfig/network-scripts/ifcfg-${public_interface}",
            line   => 'ZONE=public',
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
    }

    firewalld_zone { 'internal':
        ensure  => present,
        sources => [$management_network],
    }

    $adminZoneRequire = $::osfamily ? {
        'RedHat' => [Exec['network_restart']],
        default => []
    }

    firewalld_zone { 'admin':
        ensure           => present,
        sources          => $admin_networks,
        target           => 'default',
        purge_rich_rules => true,
        purge_services   => true,
        purge_ports      => true,
        require          => $adminZoneRequire,
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
    }

    firewalld_zone { 'public':
        ensure           => present,
        interfaces       => [$public_interface],
        purge_rich_rules => true,
        purge_services   => true,
        purge_ports      => true,
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
    -> Class['easystack::profile::network::compute']
    -> Anchor['easystack::network::end']

}
