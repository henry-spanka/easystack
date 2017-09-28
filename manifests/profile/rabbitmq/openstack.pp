# Setup RabbitMQ Openstack
class easystack::profile::rabbitmq::openstack (
    String $password = $::easystack::config::rabbitmq_user_openstack_password,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::rabbitmq

    rabbitmq_user { 'openstack':
        admin    => false,
        password => $password,
    }
    rabbitmq_user_permissions { 'openstack@/':
        configure_permission => '.*',
        read_permission      => '.*',
        write_permission     => '.*',
    }

    rabbitmq_policy { 'ha-all@/':
        pattern    => '.*',
        priority   => 0,
        applyto    => 'all',
        definition => {
            'ha-mode'      => 'all',
        },
    }

}
