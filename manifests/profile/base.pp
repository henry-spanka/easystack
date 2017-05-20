# The base profile for easystack
class easystack::profile::base {
    # make sure the parameters are initialized
    include ::easystack

    # Setup OpenStack repository on all nodes
    class { '::openstack_extras::repo::redhat::redhat':
        gpgkey_hash => {
            '/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud' => {
                source => 'puppet:///modules/openstack_extras/RPM-GPG-KEY-CentOS-SIG-Cloud'
            }
        },
        manage_epel => false,
        manage_rdo  => false,
        manage_virt => false,
        repo_hash   => {
            'CentOS-OpenStack-Octata' => {
                descr   => 'CentOS-$releasever - Openstack Octata',
                baseurl => 'http://mirror.centos.org/centos/$releasever/cloud/$basearch/openstack-ocata/',
                gpgkey  => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud'
            }
        }
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
}
