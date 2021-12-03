# Setup SSH between Compute Nodes
class easystack::profile::nova::compute::ssh (
    String $ssh_private = $::easystack::config::nova_compute_ssh_private,
    String $ssh_public  = $::easystack::config::nova_compute_ssh_public,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::nova

    user { 'nova':
        ensure         => 'present',
        purge_ssh_keys => true,
        home           => '/var/lib/nova',
        shell          => '/bin/bash',
        require        => Anchor['easystack::openstack::install_1::end'],
        before         => Anchor['easystack::openstack::config_1::begin'],
    }

    file { '/var/lib/nova/.ssh':
        ensure  => 'directory',
        owner   => 'nova',
        group   => 'nova',
        mode    => '0700',
        require => User['nova'],
    }

    file { '/var/lib/nova/.ssh/id_rsa':
        ensure  => 'file',
        owner   => 'nova',
        group   => 'nova',
        mode    => '0600',
        content => $ssh_private,
        require => File['/var/lib/nova/.ssh'],
        notify  => [
            Service['libvirtd'],
            Service['nova-compute'],
        ],
    }

    file { '/var/lib/nova/.ssh/config':
        ensure  => 'file',
        owner   => 'nova',
        group   => 'nova',
        mode    => '0600',
        content => 'StrictHostKeyChecking no',
        require => File['/var/lib/nova/.ssh'],
        notify  => [
            Service['libvirtd'],
            Service['nova-compute'],
        ],
    }

    ssh_authorized_key { 'nova-compute':
        ensure  => 'present',
        user    => 'nova',
        type    => 'ssh-rsa',
        key     => $ssh_public,
        require => File['/var/lib/nova/.ssh'],
        notify  => [
            Service['libvirtd'],
            Service['nova-compute'],
        ],
    }

    if $::osfamily == "RedHat" {
        # See: https://www.centos.org/forums/viewtopic.php?t=9193
        selinux::module { 'nova_compute_ssh-selinux':
            ensure    => 'present',
            source_te => 'puppet:///modules/easystack/selinux/nova_compute_ssh-selinux.te',
            require   => File['/var/lib/nova/.ssh'],
            notify    => [
                Service['libvirtd'],
                Service['nova-compute'],
            ],
        }
    }

}
