# Setup RabbitMQ Resource
class easystack::profile::corosync::rabbitmq {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync
    include ::easystack::profile::rabbitmq

    # Setup rabbitmq service
    cs_primitive { 'rabbitmq-server':
        ensure          => present,
        primitive_class => 'systemd',
        primitive_type  => 'rabbitmq-server',
        require         => Class['easystack::profile::rabbitmq'],
        operations      => {
            'monitor' => {
                'interval' => '30s',
            }
        },
    }

    cs_clone { 'rabbitmq-server-clone':
        ensure     => present,
        primitive  => 'rabbitmq-server',
        require    => Cs_primitive['rabbitmq-server'],
        interleave => true,
    }

}
