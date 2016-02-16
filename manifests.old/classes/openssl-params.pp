# File::      <tt>openssl-params.pp</tt>
# Author::    Sebastien Varrette (Sebastien.Varrette@uni.lu)
# Copyright:: Copyright (c) 2011 Sebastien Varrette
# License::   GPL v3
#
# ------------------------------------------------------------------------------
# = Class: openssl::params
#
# In this class are defined as variables values that are used in other
# openssl classes.
# This class should be included, where necessary, and eventually be enhanced
# with support for more OS
#
# == Warnings
#
# /!\ Always respect the style guide available
# here[http://docs.puppetlabs.com/guides/style_guide]
#
# The usage of a dedicated param classe is advised to better deal with
# parametrized classes, see
# http://docs.puppetlabs.com/guides/parameterized_classes.html
#
# [Remember: No empty lines between comments and class definition]
#
class openssl::params {

    ######## DEFAULTS FOR VARIABLES USERS CAN SET ##########################
    # (Here are set the defaults, provide your custom variables externally)
    # (The default used is in the line with '')
    ###########################################

    # ensure the presence (or absence) of openssl
    $ensure = $openssl_ensure ? {
        ''      => 'present',
        default => $openssl_ensure
    }

    # Certificate countryName
    $country = $openssl_country ? {
        ''      => 'LU',
        default => $openssl_country
    }
    # Certificate stateOrProvinceName
    $state = $openssl_state ? {
        ''      => 'Luxembourg',
        default => $openssl_state
    }
    # Certificate localityName
    $locality = $openssl_locality ? {
        ''      => 'Luxembourg',
        default => $openssl_locality
    }
    # Certificate organizationName
    $organization = $openssl_organization ? {
        ''      => 'University of Luxembourg (UL)',
        default => $openssl_organization
    }
    # Certificate organizationalUnitName 
    $organizational_unit = $openssl_organizational_unit ? {
        ''      => 'Computer Science and Communication (CSC)',
        default => $openssl_organisational_unit
    }
    # Certificate validity (in days)
    $days = $openssl_days ? {
        ''      => 365,
        default => $openssl_days
    }
    # Certificate validity (in days) of the CA certficate (5y by default)
    $ca_days = $openssl_ca_days ? {
        ''      => 9125,
        default => $openssl_ca_days
    }
    # Email
    $email = $openssl_email ? {
        ''      => 'Sebastien.Varrette@uni.lu',
        default => $openssl_email
    }
    # Root CA common name
    $root_ca_commonname = $openssl_root_ca_commonname ? {
        ''      => "${organizational_unit} Root Authority",
        default => $openssl_root_ca_commonname
    }
    # CA common name
    $ca_commonname = $openssl_ca_commonname ? {
        ''      => "${organizational_unit} Signing Authority",
        default => $openssl_ca_commonname
    }
    # Use a root CA i.e. create not only a signing CA but also a root CA.
    $use_root_ca = $openssl_use_root_ca ? {
        ''      => false,
        default => $openssl_use_root_ca
    }
    # Revocation URL
    $ca_revocation_url = $openssl_ca_revocation_url ? {
        ''      => "https://puppet.${domain}/ca-crl.pem",
        default => $openssl_ca_revocation_url
    }
    
    #### MODULE INTERNAL VARIABLES  #########
    # (Modify to adapt to unsupported OSes)
    #######################################
    $packagename = $::operatingsystem ? {
        default => 'openssl',
    }

    $utils_packages = $::operatingsystem ? {
        /(?i-mx:ubuntu|debian)/ => [ 'ca-certificates' ],
        default => []
    }
    
    # The script provided to generate SSL certificates
    $generate_ssl_cert = '/usr/local/sbin/generate-ssl-cert.sh'

    $default_ssl_cacert = $::operatingsystem ? {
        /(?i-mx:ubuntu|debian)/ => '/etc/ssl/certs/ca-certificates.crt',
        default => '/etc/pki/tls/certs/ca-bundle.crt'
    }

    $cert_filename_suffix   = '_cert.pem'
    $csr_filename_suffix    = '_csr.pem'
    $crl_filename_suffix    = '_crl.pem'
    $key_filename_suffix    = '_key.pem'
    $pubkey_filename_suffix = '_pub.pem'
    
    # $configfile = $::operatingsystem ? {
    #     default => '/path/to/openssl.conf',
    # }

    # $configfile_mode = $::operatingsystem ? {
    #     default => '0644',
    # }

    # $configfile_owner = $::operatingsystem ? {
    #     default => 'root',
    # }

    # $configfile_group = $::operatingsystem ? {
    #     default => 'root',
    # }

    $cert_basedir = $::operatingsystem ? {
        default => '/etc/certificates',
    }
    $cert_basedir_mode = $::operatingsystem ? {
        default => '0755',
    }

    $cert_basedir_owner = $::operatingsystem ? {
        default => 'root',
    }

    $cert_basedir_group = $::operatingsystem ? {
        default => 'root',
    }
    # Directory hosting the CA
    $cadir = $::operatingsystem ? {
        default => "${cert_basedir}/CA"
    }

    # $pkgmanager = $::operatingsystem ? {
    #     /(?i-mx:ubuntu|debian)/	       => [ '/usr/bin/apt-get' ],
    #     /(?i-mx:centos|fedora|redhat)/ => [ '/bin/rpm', '/usr/bin/up2date', '/usr/bin/yum' ],
    #     default => []
    # }


}

