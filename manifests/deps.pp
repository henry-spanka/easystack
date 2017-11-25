# Easystack Anchor and Dependency Management
class easystack::deps {
    anchor { 'easystack::repo::begin': }
    -> anchor { 'easystack::repo::end': }
    -> anchor { 'easystack::base::install::begin': }
    -> anchor { 'easystack::base::install::end': }
    -> anchor { 'easystack::time::begin': }
    -> anchor { 'easystack::time::end': }
    -> anchor { 'easystack::network::begin': }
    -> anchor { 'easystack::network::end': }
    -> anchor { 'easystack::certificates::begin': }
    -> anchor { 'easystack::certificates::end': }
    -> anchor { 'easystack::memcached::begin': }
    -> anchor { 'easystack::memcached::end': }
    -> anchor { 'easystack::database::install::begin': }
    -> anchor { 'easystack::database::install::end': }
    -> anchor { 'easystack::database::bootstrap::begin': }
    -> anchor { 'easystack::database::bootstrap::end': }
    -> anchor { 'easystack::messaging::install::begin': }
    -> anchor { 'easystack::messaging::install::end': }
    ~> anchor { 'easystack::messaging::service::begin': }
    -> anchor { 'easystack::messaging::service::end': }
    -> anchor { 'easystack::haproxy::install::begin': }
    -> anchor { 'easystack::haproxy::install::end': }
    ~> anchor { 'easystack::haproxy::service::begin': }
    -> anchor { 'easystack::haproxy::service::end': }
    -> anchor { 'easystack::openstack::install_1::begin': }
    -> anchor { 'easystack::openstack::install_1::end': }
    -> anchor { 'easystack::openstack::config_1::begin': }
    -> anchor { 'easystack::openstack::config_1::end': }
    -> anchor { 'easystack::corosync::setup::begin': }
    -> anchor { 'easystack::corosync::setup::end': }
    -> anchor { 'easystack::corosync::authenticate::begin': }
    -> anchor { 'easystack::corosync::authenticate::end': }
    -> anchor { 'easystack::database::service::begin': }
    -> anchor { 'easystack::database::service::end': }
    -> anchor { 'easystack::openstack::dbsync_1::begin': }
    -> anchor { 'easystack::openstack::dbsync_1::end': }
    -> anchor { 'easystack::openstack::service_1::begin': }
    -> anchor { 'easystack::openstack::service_1::end': }
    -> anchor { 'easystack::openstack::dbsync_2::begin': }
    -> anchor { 'easystack::openstack::dbsync_2::end': }
    -> anchor { 'easystack::openstack::service_2::begin': }
    -> anchor { 'easystack::openstack::service_2::end': }
    -> anchor { 'easystack::filebeat::begin': }
    -> anchor { 'easystack::filebeat::end': }
    -> anchor { 'easystack::netdata::begin': }
    -> anchor { 'easystack::netdata::end': }

    Anchor['easystack::database::install::end']
    ~> Anchor['easystack::database::service::begin']

}
