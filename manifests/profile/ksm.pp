# Configure KSM sharing
class easystack::profile::ksm {
    include ::easystack

    service { 'ksm':
        hasrestart => true,
        hasstatus  => true,
        enable     => true,
        tag        => 'ksm-service'
    }

    service { 'ksmtuned':
        ensure     => 'running',
        hasrestart => true,
        hasstatus  => true,
        enable     => true,
        tag        => 'ksm-service'
    }

    if $::osfamily == "RedHat" {
        Package['qemu-kvm-ev'] -> Service <|tag == 'ksm-service'|>
    }

}
