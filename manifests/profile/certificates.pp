# Setup Certificates
class easystack::profile::certificates {
    # make sure the parameters are initialized
    include ::easystack

    contain ca_cert

    ca_cert::ca { 'myVirtualserverRootCA':
        ensure => 'trusted',
        source => 'puppet:///modules/easystack/certificates/myVirtualserverRootCA.pem',
    }


    Anchor['easystack::certificates::begin']
    -> Class['easystack::profile::certificates']
    -> Anchor['easystack::certificates::end']
}
