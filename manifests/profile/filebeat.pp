# Setup Filebeat
class easystack::profile::filebeat (
    String $filebeat_host           = $::easystack::config::filebeat_host,
) {
    # make sure the parameters are initialized
    include ::easystack

    class { 'filebeat':
        outputs => {
            'logstash' => {
                'hosts' => [
                    $filebeat_host,
                ],
                'ssl'   => {
                    'enabled' => true,
                },
            },
        },
    }

    contain filebeat

    filebeat::prospector { 'syslog':
        paths    => [
            '/var/log/messages',
            '/var/log/secure'
        ],
        fields   => {
            'doc_type' => 'syslog',
        },
        doc_type => undef,
    }

    filebeat::prospector { 'nova':
        paths    => [
            '/var/log/nova/*.log',
        ],
        fields   => {
            'doc_type' => 'nova',
        },
        doc_type => undef,
    }

    filebeat::prospector { 'neutron':
        paths    => [
            '/var/log/neutron/*.log',
        ],
        fields   => {
            'doc_type' => 'neutron',
        },
        doc_type => undef,
    }

    filebeat::prospector { 'glance':
        paths    => [
            '/var/log/glance/*.log',
        ],
        fields   => {
            'doc_type' => 'glance',
        },
        doc_type => undef,
    }

    filebeat::prospector { 'httpd':
        paths    => [
            '/var/log/httpd/*.log',
        ],
        fields   => {
            'doc_type' => 'http',
        },
        doc_type => undef,
    }

    filebeat::prospector { 'horizon':
        paths    => [
            '/var/log/horizon/*.log',
        ],
        fields   => {
            'doc_type' => 'horizon',
        },
        doc_type => undef,
    }

    filebeat::prospector { 'keystone':
        paths    => [
            '/var/log/keystone/*.log',
        ],
        fields   => {
            'doc_type' => 'keystone',
        },
        doc_type => undef,
    }

    filebeat::prospector { 'mariadb':
        paths    => [
            '/var/log/mariadb/*.log',
        ],
        fields   => {
            'doc_type' => 'mariadb',
        },
        doc_type => undef,
    }

    filebeat::prospector { 'pacemaker':
        paths    => [
            '/var/log/pacemaker.log',
        ],
        fields   => {
            'doc_type' => 'pacemaker',
        },
        doc_type => undef,
    }

    filebeat::prospector { 'pcsd':
        paths    => [
            '/var/log/pcsd/*.log',
        ],
        fields   => {
            'doc_type' => 'pcsd',
        },
        doc_type => undef,
    }

    filebeat::prospector { 'cron':
        paths    => [
            '/var/log/cron',
        ],
        fields   => {
            'doc_type' => 'cron',
        },
        doc_type => undef,
    }

    filebeat::prospector { 'rabbitmq':
        paths    => [
            '/var/log/rabbitmq/*.log',
        ],
        fields   => {
            'doc_type' => 'rabbitmq',
        },
        doc_type => undef,
    }

    filebeat::prospector { 'libvirt':
        paths    => [
            '/var/log/libvirt/*.log',
        ],
        fields   => {
            'doc_type' => 'libvirt',
        },
        doc_type => undef,
    }


    Anchor['easystack::filebeat::begin']
    -> Class['easystack::profile::filebeat']
    -> Anchor['easystack::filebeat::end']
}
