# Setup Neutron Metadata Agent
class easystack::profile::neutron::agents::metadata (
    String $vip     = $::easystack::config::controller_vip,
    String $shared_secret = $::easystack::config::neutron_metadata_shared_secret,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::neutron

    class { '::neutron::agents::metadata':
        metadata_ip   => $vip,
        shared_secret => $shared_secret,
    }

    firewalld_service { 'Allow metadata requests to neutron metadata agent':
        ensure  => present,
        service => 'http',
        zone    => 'public',
        tag     => 'neutron-firewall',
    }

    firewalld_direct_rule {'Allow metadata requests forwarding ipv4':
        ensure        => 'present',
        inet_protocol => 'ipv4',
        table         => 'filter',
        chain         => 'FORWARD',
        priority      => 1,
        args          => '-p tcp --dport=80 -j ACCEPT',
    }

    firewalld_direct_rule {'Allow metadata requests forwarding ipv6':
        ensure        => 'present',
        inet_protocol => 'ipv6',
        table         => 'filter',
        chain         => 'FORWARD',
        priority      => 1,
        args          => '-p tcp --dport=80 -j ACCEPT',
    }

}
