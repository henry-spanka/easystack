# Setup Ceph Monitor
class easystack::profile::ceph::monitor (
    String $mon_key           = $::easystack::config::ceph_mon_key,
    String $admin_key         = $::easystack::config::ceph_admin_key,
    String $bootstrap_osd_key = $::easystack::config::ceph_bootstrap_osd_key,
    Array $monitors           = $::easystack::config::ceph_monitors,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::ceph

    include ::firewalld

    firewalld_port { 'Allow ceph monitor on port 6789 tcp':
        ensure   => present,
        zone     => 'public',
        port     => 6789,
        protocol => 'tcp',
        tag      => 'ceph-firewall',
    }

    ceph::mon { $::hostname:
        key => $mon_key,
    }

    Ceph::Key {
        inject         => true,
        inject_as_id   => 'mon.',
        inject_keyring => "/var/lib/ceph/mon/ceph-${::hostname}/keyring",
    }

    ceph::key { 'client.admin':
        secret  => $admin_key,
        cap_mon => 'allow *',
        cap_osd => 'allow *',
        cap_mds => 'allow',
    }

    ceph::key { 'client.bootstrap-osd':
        secret  => $bootstrap_osd_key,
        cap_mon => 'allow profile bootstrap-osd',
    }

}
