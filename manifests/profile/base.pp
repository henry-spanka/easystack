# The base profile for easystack
class easystack::profile::base {
    # make sure the parameters are initialized
    include ::easystack

    # Setup OpenStack repository on all nodes
    file { '/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud':
        ensure => file,
        source => 'puppet:///modules/easystack/RPM-GPG-KEY-CentOS-SIG-Cloud',
    }

    yumrepo { 'CentOS-OpenStack-Octata':
        baseurl  => 'http://mirror.centos.org/centos/$releasever/cloud/$basearch/openstack-ocata/',
        descr    => 'CentOS-$releasever - Openstack Octata',
        enabled  => 1,
        gpgcheck => 1,
        gpgkey   => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud',
        require  => File['/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud'],
    }

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
}
