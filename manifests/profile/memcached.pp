# Setup Memcached Service
class easystack::profile::memcached (
    String $listen_ip   = ip_for_network($easystack::config::management_network),
    Integer $max_memory = 20,
) {
    # make sure the parameters are initialized
    include ::easystack

    class { 'memcached':
        listen_ip  => $listen_ip,
        max_memory => "${max_memory}%",
    }

    include ::firewalld

    firewalld_port { 'Allow memcached on port 11211 tcp':
        ensure   => present,
        zone     => 'public',
        port     => 11211,
        protocol => 'tcp',
        before   => Class['memcached'],
    }
}
