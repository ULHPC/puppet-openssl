# File::      <tt>common.pp</tt>
# Author::    S. Varrette, H. Cartiaux, V. Plugaru, S. Diehl aka. UL HPC Management Team (Hyacinthe.Cartiaux@uni.lu)
# Copyright:: Copyright (c) 2016 S. Varrette, H. Cartiaux, V. Plugaru, S. Diehl aka. UL HPC Management Team
# License::   Gpl-3.0
#
# ------------------------------------------------------------------------------
# = Class: openssl::common
#
# Base class to be inherited by the other openssl classes
#
# Note: respect the Naming standard provided here[http://projects.puppetlabs.com/projects/puppet/wiki/Module_Standards]
class openssl::common {

    # Load the variables used in this module. Check the openssl-params.pp file
    require openssl::params

    package { 'openssl':
        ensure => $openssl::ensure,
        name   => $openssl::params::packagename,
    }

    if $openssl::params::utils_packages != [] {
        package { $openssl::params::utils_packages:
            ensure  => $openssl::ensure,
        }
    }

    # The script used to generate X.509 certificates
    file { $openssl::params::generate_ssl_cert:
        ensure  => $openssl::ensure,
        source  => 'puppet:///modules/openssl/generate-ssl-cert.sh',
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        require => Package['openssl']
    }

}
