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
        before => Yumrepo['CentOS-OpenStack-Pike'],
    }

    yumrepo { 'CentOS-OpenStack-Pike':
        baseurl  => 'http://mirror.centos.org/centos/$releasever/cloud/$basearch/openstack-pike/',
        descr    => 'CentOS-$releasever - Openstack Pike',
        enabled  => 1,
        gpgcheck => 1,
        gpgkey   => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud',
        priority => 20,
        require  => File['/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud'],
    }

    Anchor['easystack::repo::begin']
    -> Class['easystack::profile::base::repo']
    ~> Anchor['easystack::repo::end']

}
