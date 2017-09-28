# Setup Glance Nfs Backend
class easystack::profile::glance::backend::nfs (
    String $glance_nfs_device = $::easystack::config::glance_nfs_device,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::glance

    # See: https://jira.mariadb.org/browse/MDEV-9852
    selinux::module { 'glance_api_nfs-selinux':
        ensure    => 'present',
        source_te => 'puppet:///modules/easystack/selinux/glance_api_nfs-selinux.te',
        before    => File['/var/lib/glance/images'],
    }

    file { '/var/lib/glance/images':
        ensure  => 'directory',
        owner   => 'glance',
        group   => 'glance',
        mode    => '0750',
        require => Anchor['glance::install::end'],
    }

    mount { '/var/lib/glance/images':
        ensure  => 'mounted',
        device  => $glance_nfs_device,
        fstype  => 'nfs',
        options => 'defaults',
        atboot  => true,
        require => File['/var/lib/glance/images'],
    }

    class { 'glance::backend::file':
        require => Mount['/var/lib/glance/images'],
    }

    contain glance::backend::file

}
