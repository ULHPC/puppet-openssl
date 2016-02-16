# File::      <tt>openssl-ca.pp</tt>
# Author::    Sebastien Varrette (<Sebastien.Varrette@uni.lu>)
# Copyright:: Copyright (c) 2012 Sebastien Varrette (www[http://varrette.gforge.uni.lu])
# License::   GPLv3
#
# ------------------------------------------------------------------------------
# = Class: openssl::ca
#
# Configure and manage a Certificate Authority (CA), typically to initiate a
# chain of trust.
#
# == Parameters:
#
# $ensure:: *Default*: 'present'. Ensure the presence (or absence) of
#     openssl::ca
# $basedir:: *Default*: '/etc/certificates'. The basedir where the CA will be
#     created (in the CA directory typically)
# $country:: *Default*: 'LU'
#
#
#
# == Actions:
#
# Install and configure openssl::ca
#
# == Requires:
#
# n/a
#
# == Sample usage:
#
#     import openssl::ca
#
# You can then specialize the various aspects of the configuration,
# for instance:
#
#      class { 'openssl::ca':
#          ensure => 'present'
#      }
#
# == Warnings
#
# /!\ Always respect the style guide available
# here[http://docs.puppetlabs.com/guides/style_guide]
#
# [Remember: No empty lines between comments and class definition]
#
class openssl::ca (
    $ensure              = $openssl::params::ensure,
    $basedir             = $openssl::params::cert_basedir,
    $commonname          = $openssl::params::ca_commonname,
    $country             = $openssl::params::country,
    $state               = $openssl::params::state,
    $locality            = $openssl::params::locality,
    $organization        = $openssl::params::organization,
    $organizational_unit = $openssl::params::organizational_unit,
    $days                = $openssl::params::ca_days,
    $email               = $openssl::params::email,
    $owner               = $openssl::params::cert_basedir_owner,
    $group               = $openssl::params::cert_basedir_group,
    $mode                = $openssl::params::cert_basedir_mode,
    $ca_revocation_url   = $openssl::params::ca_revocation_url,
    $use_root_ca         = $openssl::params::use_root_ca,
    $root_ca_commonname  = $openssl::params::root_ca_commonname
)
inherits openssl::params
{

    info ("Configuring openssl::ca (with ensure = ${ensure}) in ${basedir} (use Root CA = ${use_root_ca})")

    if ! ($ensure in [ 'present', 'absent' ]) {
        fail("openssl::ca 'ensure' parameter must be set to either 'absent' or 'present'")
    }

    case $::operatingsystem {
        debian, ubuntu:         { include openssl::ca::debian }
        redhat, fedora, centos: { include openssl::ca::redhat }
        default: {
            fail("Module $module_name is not supported on $operatingsystem")
        }
    }
}

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
    if !defined( File["${openssl::ca::basedir}"] ){
        exec { "mkdir -p ${openssl::ca::basedir}":
            path    => "/usr/bin:/usr/sbin/:/bin:/sbin",
            unless  => "test -d ${openssl::ca::basedir}",
        }
        file { "${openssl::ca::basedir}":
            ensure  => "directory",
            owner   => "${openssl::ca::owner}",
            group   => "${openssl::ca::group}",
            mode    => "${openssl::ca::mode}",
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
        $ca_basedir = "${rootcadir}"
    }
    else
    {
        $ca_basedir = "${cadir}"
    }
    
    $cacertfile = "${openssl::ca::basedir}/ca${openssl::params::cert_filename_suffix}"
    $cacrlfile  = "${openssl::ca::basedir}/ca${openssl::params::crl_filename_suffix}"

    file { [ "${cadir}", "${certdir}", "${templatedir}" ]:
        ensure  => "directory",
        owner   => "${openssl::ca::owner}",
        group   => "${openssl::ca::group}",
        mode    => "${openssl::ca::mode}",
        require => File["${openssl::ca::basedir}"]
    }

    # prepare the template files
    file { "${templatedir}/Makefile":
        ensure  => "${openssl::ca::ensure}",
        owner   => "${openssl::ca::owner}",
        group   => "${openssl::ca::group}",
        mode    => '0644',
        content => template("openssl/CA/Makefile.erb"),
        require => File["${templatedir}"],
    }
    file { "${templatedir}/openssl.cnf":
        ensure  => "${openssl::ca::ensure}",
        owner   => "${openssl::ca::owner}",
        group   => "${openssl::ca::group}",
        mode    => '0644',
        source  => "puppet:///modules/openssl/ca/openssl.cnf",
        require => File["${templatedir}"],
    }

    # prepare the root CA
    if $openssl::ca::use_root_ca {
        file { "${rootcadir}":
            ensure  => 'directory',
            owner   => 'root',
            group   => 'root',
            mode    => '0700',
            require => File["${openssl::ca::basedir}"]
        }
        openssl::ca::init { "${rootcadir}":
            commonname  => "${openssl::ca::root_ca_commonname}",
            email       => "${openssl::ca::email}",
            owner       => 'root',
            group       => 'root',
            mode        => '0600',
            templatedir => "${templatedir}"
        }
    }

    # Prepare the CA directory
    openssl::ca::init { "${cadir}":
        commonname  => "${openssl::ca::ca_commonname}",
        email       => "${openssl::ca::email}",
        owner       => "${openssl::ca::owner}",
        group       => "${openssl::ca::group}",
        mode        => '0600',
        templatedir => "${templatedir}"
    }

    # Sign the CA certificate with the Root CA
    if $openssl::ca::use_root_ca {
        # Generate the new CSR for the Signing CA
        openssl::x509::generate { 'signing-ca':
            key         => "${cadir}/private/ca-key.pem",
            config      => "${cadir}/openssl.cnf",
            basedir     => "${cadir}",
            owner       => "${openssl::ca::owner}",
            group       => "${openssl::ca::group}",
            self_signed => false,
            require     => Openssl::Ca::Init["${cadir}"]
        }
        # ... And sign it by the Root CA
        openssl::ca::sign { 'signing-ca':
            basedir => "${cadir}",
            cadir   => "${rootcadir}",
            create_signing_authority  => true,
            require => Openssl::X509::Generate['signing-ca']
        }
        # # And replace the ca-cert.pem file of the Signing CA
        exec { "rm -f ${cadir}/ca-cert.pem":
            path    => "/usr/bin:/usr/sbin/:/bin:/sbin",
            cwd     => "${cadir}",
            onlyif  => "test -f ${cadir}/ca-cert.pem",
            require => Openssl::Ca::Sign['signing-ca']
        }
        file { "${cadir}/ca-cert.pem":
            ensure => 'link',
            target => "signing-ca${openssl::params::cert_filename_suffix}",
            require => Exec["rm -f ${cadir}/ca-cert.pem"]
        }
        $cert_requires = [ Openssl::Ca::Sign[ 'signing-ca' ], Openssl::X509::Generate["$fqdn"] ]
    }
    else
    {
       $cert_requires = [ Openssl::Ca::Init["${cadir}"], Openssl::X509::Generate["$fqdn"] ]
    }


    # Add the link to the (root) CA certificate
    file { "${cacertfile}":
        ensure  => 'link',
        target  => "${ca_basedir}/ca-cert.pem",
        require => Openssl::Ca::Init["${cadir}"]
    }
    file { "${cacrlfile}":
        ensure  => 'link',
        target  => "${ca_basedir}/ca-crl.pem",
        require => Openssl::Ca::Init["${cadir}"]
    }

    file { "${certdir}/ca.pem":
        ensure  => 'link',
        target  => "${cacertfile}",
        require => File["${certdir}"]
    }

    # Create the certficiate for the current host:
    openssl::x509::generate { "$fqdn":
        email       => "hpc-sysadmins@uni.lu",
        ensure      => "${openssl::ca::ensure}",
        owner       => "${openssl::ca::owner}",
        group       => "${openssl::ca::group}",
        basedir     => "${certdir}",
        self_signed => false
    }

    # ... And sign it with the Signing CA
    openssl::ca::sign { "$fqdn":
        basedir => "${certdir}",
        owner   => "${openssl::ca::owner}",
        group   => "${openssl::ca::group}",
        cadir   => "${cadir}",
        require => $cert_requires
    }
}

# ------------------------------------------------------------------------------
# = Class: openssl::ca::debian
#
# Specialization class for Debian systems
class openssl::ca::debian inherits openssl::ca::common { }

# ------------------------------------------------------------------------------
# = Class: openssl::ca::redhat
#
# Specialization class for Redhat systems
class openssl::ca::redhat inherits openssl::ca::common { }







