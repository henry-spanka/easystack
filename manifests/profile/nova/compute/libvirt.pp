# Setup Nova Compute Libvirt Driver
class easystack::profile::nova::compute::libvirt (
    String $listen_ip       = ip_for_network($::easystack::config::management_network),
    String $vip             = $::easystack::config::controller_vip,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::nova

    # We need to use QEMU for virtual servers and the old QEMU version
    # on CentOS 7 does not support disk discarding.
    if ($::is_virtual) {
        $hw_disk_discard = undef
        $libvirt_virt_type = 'qemu'
    } else {
        $hw_disk_discard = 'unmap'
        $libvirt_virt_type = 'kvm'
    }

    class { 'nova::compute::libvirt':
        libvirt_hw_disk_discard => $hw_disk_discard,
        vncserver_listen        => '0.0.0.0',
        libvirt_virt_type       => $libvirt_virt_type,
    }

    include ::firewalld

    firewalld_port { 'Allow libvirt console port range from 5900 to 6900 tcp':
        ensure   => present,
        zone     => 'public',
        port     => '5900-6900',
        protocol => 'tcp',
        tag      => 'nova-firewall',
        before   => Service['httpd'],
    }

}