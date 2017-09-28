# Define Neutron Relationships when managed through pacemaker
class easystack::profile::corosync::deps::neutron {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync
    include ::easystack::profile::neutron

    Anchor['neutron::config::end'] -> Exec['reauthenticate-across-all-nodes']
    Anchor['easystack::profile::mariadb::end'] -> Anchor['neutron::db::begin']

}
