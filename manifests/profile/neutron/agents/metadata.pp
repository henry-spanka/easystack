# Setup Neutron Metadata Agent
class easystack::profile::neutron::agents::metadata (
    String $admin_endpoint = $::easystack::config::admin_endpoint,
    String $shared_secret  = $::easystack::config::neutron_metadata_shared_secret,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::neutron

    class { '::neutron::agents::metadata':
        metadata_ip       => $admin_endpoint,
        metadata_host     => $admin_endpoint,
        metadata_port     => '8775',
        metadata_protocol => 'https',
        shared_secret     => $shared_secret,
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
