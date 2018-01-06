# Setup Nova Compute Libvirt Driver
class easystack::profile::nova::compute::libvirt (
    String $listen_ip       = ip_for_network($::easystack::config::management_network),
    String $vip             = $::easystack::config::controller_vip,
    String $rescue_image_id = $::easystack::config::rescue_image_id,
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

    # Install qemu-kvm-ev as Qemu Version is too old otherwise
    package { 'centos-release-qemu-ev':
        ensure => 'installed',
    }

    package { 'qemu-kvm-ev':
        ensure  => 'installed',
        require => Package['centos-release-qemu-ev'],
        before  => Class['nova::compute::libvirt'],
    }

    class { 'nova::compute::libvirt':
        libvirt_hw_disk_discard => $hw_disk_discard,
        vncserver_listen        => '0.0.0.0',
        libvirt_virt_type       => $libvirt_virt_type,
        libvirt_inject_password => true,
        libvirt_cpu_mode        => 'custom',
        libvirt_cpu_model       => 'kvm64',
    }

    include ::firewalld

    firewalld_port { 'Allow libvirt console port range from 5900 to 6900 tcp':
        ensure   => present,
        zone     => 'internal',
        port     => '5900-6900',
        protocol => 'tcp',
        tag      => 'nova-firewall',
    }

    # Virtlockd is socket activated and therefore auto booting does not work
    Service <| title == 'virtlockd' |> {
        enable => undef,
        ensure => undef,
    }

    nova_config {
        'workarounds/disable_libvirt_livesnapshot': value => false;
        # Incorrectly set so we need to remove this option if set
        'libvirt/disable_libvirt_livesnapshot':     ensure => absent;
        'libvirt/rescue_image_id':                  value => $rescue_image_id;
    }

}
