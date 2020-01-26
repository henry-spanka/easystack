# Setup Nova Compute Libvirt Driver
class easystack::profile::nova::compute::libvirt (
    String $listen_ip                 = ip_for_network($::easystack::config::management_network),
    String $vip                       = $::easystack::config::controller_vip,
    Optional[String] $rescue_image_id = $::easystack::config::rescue_image_id,
    String $cpu_mode                  = $::easystack::config::libvirt_cpu_mode,
    Optional[String] $cpu_model       = $::easystack::config::libvirt_cpu_model,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::nova
    include ::easystack::profile::base::qemu

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
        libvirt_hw_disk_discard       => $hw_disk_discard,
        vncserver_listen              => '0.0.0.0',
        libvirt_virt_type             => $libvirt_virt_type,
        libvirt_inject_password       => true,
        libvirt_cpu_mode              => $cpu_mode,
        libvirt_cpu_model             => $cpu_model,
        libvirt_snapshot_image_format => 'raw',
        libvirt_disk_cachemodes       => ['network=writeback'],
    }

    # Let's install custom CPU map
    if ($cpu_mode == 'custom') {
        file { '/usr/share/libvirt/cpu_map.xml':
            ensure  => 'file',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/easystack/libvirt/cpu_map.xml',
            require => Package['libvirt'],
            before  => Service['libvirt'],
            notify  => Service['libvirt'],
        }
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
    }

    if ($rescue_image_id) {
        nova_config {
            'libvirt/rescue_image_id': value => $rescue_image_id;
        }
    } else {
        nova_config {
            'libvirt/rescue_image_id': ensure => absent;
        }
    }

    include patch

    # Currently if a nova image doesn't have a parent
    # image nova will fail because the parent pool cannot
    # be found. This patch sets the parent pool to
    # 'images' by default in the case that the original
    # nova image is flattened.
    patch::file { '/usr/lib/python2.7/site-packages/nova/virt/libvirt/imagebackend.py':
        diff_source => 'puppet:///modules/easystack/nova/default_snapshot_pool.diff',
        require     => Anchor['easystack::openstack::install_1::end'],
        notify      => Anchor['nova::service::begin'],
    }

    # If we are restoring from a snapshot that was created
    # earlier for this instance, we want to flatten the image because otherwise
    # the backing image (snapshot) cannot be deleted because the instance
    # is currently using it.
    # Requires nova 17.0.12 or higher (see: https://bugs.launchpad.net/nova/rocky/+bug/1653953)
    patch::file { '/usr/lib/python2.7/site-packages/nova/virt/libvirt/driver.py':
        diff_source => 'puppet:///modules/easystack/nova/snapshot_rebuild_flatten.diff',
        require     => Anchor['easystack::openstack::install_1::end'],
        notify      => Anchor['nova::service::begin'],
    }

    Class['easystack::profile::base::qemu']
    -> Class['nova::compute::libvirt']

}
