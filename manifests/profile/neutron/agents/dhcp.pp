# Setup Neutron DHCP Agent
class easystack::profile::neutron::agents::dhcp {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::neutron

    class { '::neutron::agents::dhcp':
        interface_driver         => 'linuxbridge',
        dhcp_driver              => 'neutron.agent.linux.dhcp.Dnsmasq',
        enable_isolated_metadata => true,
    }

    firewalld_service { 'Allow dhcp requests to neutron dhcp agent':
        ensure  => present,
        service => 'dhcp',
        zone    => 'public',
        tag     => 'neutron-firewall',
    }

    firewalld_direct_rule {'Allow dhcp requests forwarding ipv4':
        ensure        => 'present',
        inet_protocol => 'ipv4',
        table         => 'filter',
        chain         => 'FORWARD',
        priority      => 1,
        args          => '-p udp --sport 68 --dport=67 -j ACCEPT',
    }

    firewalld_direct_rule {'Allow dhcp requests forwarding ipv6':
        ensure        => 'present',
        inet_protocol => 'ipv6',
        table         => 'filter',
        chain         => 'FORWARD',
        priority      => 1,
        args          => '-p udp --sport 68 --dport=67 -j ACCEPT',
    }

    firewalld_direct_rule {'Allow dhcp offers forwarding ipv4':
        ensure        => 'present',
        inet_protocol => 'ipv4',
        table         => 'filter',
        chain         => 'FORWARD',
        priority      => 1,
        args          => '-p udp --sport 67 --dport=68 -j ACCEPT',
    }

    firewalld_direct_rule {'Allow dhcp offers forwarding ipv6':
        ensure        => 'present',
        inet_protocol => 'ipv6',
        table         => 'filter',
        chain         => 'FORWARD',
        priority      => 1,
        args          => '-p udp --sport 67 --dport=68 -j ACCEPT',
    }

}
