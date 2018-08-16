# The base qemu profile for easystack
class easystack::profile::base::qemu {
    # make sure the parameters are initialized
    include easystack

    # Install qemu-kvm-ev as Qemu Version is too old otherwise
    package { 'centos-release-qemu-ev':
        ensure  => 'installed',
        require => Anchor['easystack::repo::begin'],
        before  => Anchor['easystack::repo::end'],
    }

    package { 'qemu-kvm-ev':
        ensure  => 'installed',
        require => [
            Package['centos-release-qemu-ev'],
            Anchor['easystack::base::install::begin'],
        ],
        before  => Anchor['easystack::base::install::end'],
    }
}
