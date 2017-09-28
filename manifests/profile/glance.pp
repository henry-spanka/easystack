# Setup Glance Service
class easystack::profile::glance {
    # make sure the parameters are initialized
    include ::easystack

    include ::firewalld

    contain ::glance

    Anchor['easystack::openstack::install_1::begin']
    -> Anchor['glance::install::begin']
    -> Anchor['glance::install::end']
    -> Anchor['easystack::openstack::install_1::end']

    Anchor['easystack::openstack::config_1::begin']
    -> Anchor['glance::config::begin']
    -> Anchor['glance::config::end']
    -> Anchor['easystack::openstack::config_1::end']

    Anchor['easystack::openstack::dbsync_2::begin']
    -> Anchor['glance::db::begin']
    -> Anchor['glance::db::end']
    -> Anchor['glance::dbsync::begin']
    -> Anchor['glance::dbsync::end']
    -> Anchor['easystack::openstack::dbsync_2::end']

    Anchor['easystack::openstack::service_2::begin']
    -> Anchor['glance::service::begin']
    -> Anchor['glance::service::end']
    -> Anchor['easystack::openstack::service_2::end']

    Firewalld_port <|tag == 'glance-firewall'|>
    -> Anchor['easystack::openstack::service_2::begin']

}
