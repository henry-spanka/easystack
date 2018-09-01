# The base repo profile for easystack
class easystack::profile::base::repo {
    # make sure the parameters are initialized
    include easystack

    # Setup OpenStack repository on all nodes
    file { '/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud':
        ensure => file,
        source => 'puppet:///modules/easystack/RPM-GPG-KEY-CentOS-SIG-Cloud',
    }

    package { 'yum-plugin-priorities':
        ensure => installed,
        before => Yumrepo['CentOS-OpenStack-Queens'],
    }

    yumrepo { 'CentOS-OpenStack-Pike':
        ensure => 'absent',
    }

    yumrepo { 'CentOS-OpenStack-Queens':
        baseurl  => 'http://mirror.centos.org/centos/$releasever/cloud/$basearch/openstack-queens/',
        descr    => 'CentOS-$releasever - Openstack Queens',
        enabled  => 1,
        gpgcheck => 1,
        gpgkey   => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud',
        priority => 20,
        require  => File['/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud'],
    }

    package { 'epel-release':
        ensure => 'installed',
    }

    yumrepo { 'epel':
        enabled  => 1,
        priority => 99,
        require  => Package['epel-release'],
    }

    # We do have packages that require epel and dependency resolution fails
    # if epel is enabled because Yum tries to install python2-pyngus instead.
    # Message: Package python-pyngus is obsoleted by python2-pyngus, trying to install python2-pyngus-2.2.2-1.el7.noarch instead
    # Therefore we will install python-pyngus explicitely.
    package { 'python-pyngus':
        ensure          => 'installed',
        install_options => ['--disablerepo', 'epel'],
        require         => [
            Yumrepo['CentOS-OpenStack-Queens'],
            Yumrepo['epel'],
        ],
    }

    Anchor['easystack::repo::begin']
    -> Class['easystack::profile::base::repo']
    ~> Anchor['easystack::repo::end']

}
