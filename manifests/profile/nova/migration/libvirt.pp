# Setup Nova Libvirt migration
class easystack::profile::nova::migration::libvirt (
    String $listen_ip       = ip_for_network($::easystack::config::management_network),
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::nova

    include ::easystack::profile::nova::compute::libvirt

    # We need to use QEMU for virtual servers and the old QEMU version
    # on CentOS 7 does not support disk discarding.
    class { 'nova::migration::libvirt':
        listen_address => $listen_ip,
    }

    include ::firewalld

    firewalld_port { 'Allow libvirt migration port 16509 tcp':
        ensure   => present,
        zone     => 'internal',
        port     => '16509',
        protocol => 'tcp',
        tag      => 'libvirt-firewall',
    }

    firewalld_port { 'Allow qemu migration ports 49152 to 49215 tcp':
        ensure   => present,
        zone     => 'internal',
        port     => '49152-49215',
        protocol => 'tcp',
        tag      => 'libvirt-firewall',
    }

}
