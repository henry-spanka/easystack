# The base profile for easystack
class easystack::profile::base {
    # make sure the parameters are initialized
    include easystack

    if $::osfamily == "RedHat" {
        require easystack::profile::base::repo

        package { 'openstack-selinux':
            ensure => installed,
            name   => 'openstack-selinux'
        }

        # Set Selinux to enforcing modules
        class { 'selinux':
            mode => 'enforcing',
            type => 'targeted',
        }

        # Install MySQL python library
        package { 'python2-PyMySQL':
            ensure => installed,
            name   => 'python2-PyMySQL'
        }
    }

    package { 'python-openstackclient':
        ensure => installed,
        name   => 'python-openstackclient'
    }

    Anchor['easystack::base::install::begin']
    -> Class['easystack::profile::base']
    ~> Anchor['easystack::base::install::end']

}
