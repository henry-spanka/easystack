# Configure KSM sharing
class easystack::profile::ksm {
    include ::easystack

    service { 'ksm':
        hasrestart => true,
        hasstatus  => true,
        enable     => true,
    }

    service { 'ksmtuned':
        ensure     => 'running',
        hasrestart => true,
        hasstatus  => true,
        enable     => true,
    }

    Class ['easystack::profile::nova::compute::libvirt']
    -> Class['easystack::profile::ksm']

}
