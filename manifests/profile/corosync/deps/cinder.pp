# Define Cinder Relationships when managed through pacemaker
class easystack::profile::corosync::deps::cinder {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync
    include ::easystack::profile::cinder

    Anchor['cinder::config::end'] -> Exec['reauthenticate-across-all-nodes']
    Anchor['easystack::profile::mariadb::end'] -> Anchor['cinder::db::begin']

}
