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
        priority => absent,
        require  => File['/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud'],
    }

    package { 'epel-release':
        ensure => 'absent',
    }

    Anchor['easystack::repo::begin']
    -> Class['easystack::profile::base::repo']
    ~> Anchor['easystack::repo::end']

}
