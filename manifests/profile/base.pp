# The base profile for easystack
class easystack::profile::base {
    # make sure the parameters are initialized
    include easystack
    require easystack::profile::base::repo

    package { 'python-openstackclient':
        ensure => installed,
        name   => 'python-openstackclient'
    }

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

    Anchor['easystack::base::install::begin']
    -> Class['easystack::profile::base']
    ~> Anchor['easystack::base::install::end']

}
