# Define Keystone Relationships when managed through pacemaker
class easystack::profile::corosync::deps::keystone {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync
    include ::easystack::profile::keystone
    Anchor['keystone::config::end'] -> Exec['reauthenticate-across-all-nodes']
    Anchor['easystack::profile::mariadb::end'] -> Anchor['keystone::db::begin']

}
