# Define Nova Relationships when managed through pacemaker
class easystack::profile::corosync::deps::nova {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync
    include ::easystack::profile::nova

    Anchor['nova::config::end'] -> Exec['reauthenticate-across-all-nodes']
    Anchor['easystack::profile::mariadb::end'] -> Anchor['nova::db::begin']

}
