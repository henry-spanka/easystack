# Setup Memcached Service
class easystack::profile::mariadb::repo {
    # make sure the parameters are initialized
    include ::easystack

    # Setup MariaDB
    yumrepo { 'MariaDB':
        baseurl  => 'http://yum.mariadb.org/10.1/centos7-amd64',
        descr    => 'MariaDB 10.1',
        enabled  => 1,
        gpgcheck => 1,
        gpgkey   => 'https://yum.mariadb.org/RPM-GPG-KEY-MariaDB',
    }
}
