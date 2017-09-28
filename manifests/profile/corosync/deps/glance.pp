# Define Glance Relationships when managed through pacemaker
class easystack::profile::corosync::deps::glance {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync
    include ::easystack::profile::glance

    Anchor['glance::config::end'] -> Exec['reauthenticate-across-all-nodes']
    Anchor['easystack::profile::mariadb::end'] -> Anchor['glance::db::begin']

}
