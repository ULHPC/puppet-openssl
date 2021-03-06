# ------------------------------------------------------------------------------
# = Class: openssl::ca::common
#
# Base class to be inherited by the other openssl::ca classes
#
# Note: respect the Naming standard provided
# here[http://projects.puppetlabs.com/projects/puppet/wiki/Module_Standards]
class openssl::ca::common {

    # Load the variables used in this module. Check the infiniband-params.pp file
    require openssl::params

    if !defined( Package['make'] ) {
        package { 'make':
            ensure => 'present'
        }
    }

    # The root directory of the CA
    if !defined( File[$openssl::ca::basedir] ){
        exec { "mkdir -p ${openssl::ca::basedir}":
            path   => '/usr/bin:/usr/sbin/:/bin:/sbin',
            unless => "test -d ${openssl::ca::basedir}",
        }
        file { $openssl::ca::basedir:
            ensure  => 'directory',
            owner   => $openssl::ca::owner,
            group   => $openssl::ca::group,
            mode    => $openssl::ca::mode,
            require => Exec["mkdir -p ${openssl::ca::basedir}"]
        }
    }


    # Prepare the basic directories and variables (similar to the Puppet
    # built-in CA)
    $templatedir   = "${openssl::ca::basedir}/.template"
    $cadir         = "${openssl::ca::basedir}/ca"
    $certdir       = "${openssl::ca::basedir}/certs"

    if $openssl::ca::use_root_ca {
        $rootcadir  = "${openssl::ca::basedir}/rootCA"
        $ca_basedir = $rootcadir
    }
    else
    {
        $ca_basedir = $cadir
    }

    $cacertfile = "${openssl::ca::basedir}/ca${openssl::params::cert_filename_suffix}"
    $cacrlfile  = "${openssl::ca::basedir}/ca${openssl::params::crl_filename_suffix}"

    file { [ $cadir, $certdir, $templatedir ]:
        ensure  => 'directory',
        owner   => $openssl::ca::owner,
        group   => $openssl::ca::group,
        mode    => $openssl::ca::mode,
        require => File[$openssl::ca::basedir]
    }

    # prepare the template files
    file { "${templatedir}/Makefile":
        ensure  => $openssl::ca::ensure,
        owner   => $openssl::ca::owner,
        group   => $openssl::ca::group,
        mode    => '0644',
        content => template('openssl/CA/Makefile.erb'),
        require => File[$templatedir],
    }
    file { "${templatedir}/openssl.cnf":
        ensure  => $openssl::ca::ensure,
        owner   => $openssl::ca::owner,
        group   => $openssl::ca::group,
        mode    => '0644',
        source  => 'puppet:///modules/openssl/ca/openssl.cnf',
        require => File[$templatedir],
    }

    # prepare the root CA
    if $openssl::ca::use_root_ca {
        file { $rootcadir:
            ensure  => 'directory',
            owner   => 'root',
            group   => 'root',
            mode    => '0700',
            require => File[$openssl::ca::basedir]
        }
        openssl::ca::init { $rootcadir:
            commonname  => $openssl::ca::root_ca_commonname,
            email       => $openssl::ca::email,
            owner       => 'root',
            group       => 'root',
            mode        => '0600',
            templatedir => $templatedir
        }
    }

    # Prepare the CA directory
    openssl::ca::init { $cadir:
        commonname  => $openssl::ca::ca_commonname,
        email       => $openssl::ca::email,
        owner       => $openssl::ca::owner,
        group       => $openssl::ca::group,
        mode        => '0600',
        templatedir => $templatedir
    }

    # Sign the CA certificate with the Root CA
    if $openssl::ca::use_root_ca {
        # Generate the new CSR for the Signing CA
        openssl::x509::generate { 'signing-ca':
            key         => "${cadir}/private/ca-key.pem",
            config      => "${cadir}/openssl.cnf",
            basedir     => $cadir,
            owner       => $openssl::ca::owner,
            group       => $openssl::ca::group,
            self_signed => false,
            require     => Openssl::Ca::Init[$cadir]
        }
        # ... And sign it by the Root CA
        openssl::ca::sign { 'signing-ca':
            basedir                  => $cadir,
            cadir                    => $rootcadir,
            create_signing_authority => true,
            require                  => Openssl::X509::Generate['signing-ca']
        }
        # # And replace the ca-cert.pem file of the Signing CA
        exec { "rm -f ${cadir}/ca-cert.pem":
            path    => '/usr/bin:/usr/sbin/:/bin:/sbin',
            cwd     => $cadir,
            onlyif  => "test -f ${cadir}/ca-cert.pem",
            require => Openssl::Ca::Sign['signing-ca']
        }
        file { "${cadir}/ca-cert.pem":
            ensure  => 'link',
            target  => "signing-ca${openssl::params::cert_filename_suffix}",
            require => Exec["rm -f ${cadir}/ca-cert.pem"]
        }
        $cert_requires = [ Openssl::Ca::Sign[ 'signing-ca' ], Openssl::X509::Generate[$::fqdn] ]
    }
    else
    {
        $cert_requires = [ Openssl::Ca::Init[$cadir], Openssl::X509::Generate[$::fqdn] ]
    }


    # Add the link to the (root) CA certificate
    file { $cacertfile:
        ensure  => 'link',
        target  => "${ca_basedir}/ca-cert.pem",
        require => Openssl::Ca::Init[$cadir]
    }
    file { $cacrlfile:
        ensure  => 'link',
        target  => "${ca_basedir}/ca-crl.pem",
        require => Openssl::Ca::Init[$cadir]
    }

    file { "${certdir}/ca.pem":
        ensure  => 'link',
        target  => $cacertfile,
        require => File[$certdir]
    }

    # Create the certficiate for the current host:
    openssl::x509::generate { $::fqdn:
        ensure      => $openssl::ca::ensure,
        email       => $openssl::ca::email,
        owner       => $openssl::ca::owner,
        group       => $openssl::ca::group,
        basedir     => $certdir,
        self_signed => false
    }

    # ... And sign it with the Signing CA
    openssl::ca::sign { $::fqdn:
        basedir => $certdir,
        owner   => $openssl::ca::owner,
        group   => $openssl::ca::group,
        cadir   => $cadir,
        require => $cert_requires
    }
}

