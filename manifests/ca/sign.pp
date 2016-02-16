# File::      <tt>openssl-ca-sign.pp</tt>
# Author::    Sebastien Varrette (<Sebastien.Varrette@uni.lu>)
# Copyright:: Copyright (c) 2012 Sebastien Varrette (www[http://varrette.gforge.uni.lu])
# License::   GPLv3
#
# ------------------------------------------------------------------------------
# = Defines: openssl::ca::sign
#
# Signs a CSR sent by clients to produce a certificate
#
# == Parameters:
#


# == Requires:
#
# The class openssl::ca should have been instanciated.
# $email SHOULD be provided
#
# == Warnings
#
# /!\ Always respect the style guide available
# here[http://docs.puppetlabs.com/guides/style_guide]
#
# [Remember: No empty lines between comments and class defsignion]
#
define openssl::ca::sign (
    $basedir,
    $cadir,
    $csr      = '',
    $owner    = $openssl::params::cert_basedir_owner,
    $group    = $openssl::params::cert_basedir_group,
    $create_signing_authority = false
)
{
    include openssl::params
    include openssl::ca

    # $name is provided by define invocation
    $certname = $name

    $csrfile = $csr ? {
        ''      => "${basedir}/${certname}${openssl::params::csr_filename_suffix}",
        default => $csr
    }
    $certfile   = "${basedir}/${certname}${openssl::params::cert_filename_suffix}"
    $pubkeyfile = "${basedir}/${certname}${openssl::params::pubkey_filename_suffix}"

    info ("Sign the ${certname} certficate via openssl::ca::sign (in ${basedir})")

    # Sign the CSR
    $create_signing_authority_opts = $create_signing_authority ? {
        true    => '-extfile openssl.cnf -extensions v3_ca',
        default => ''
    }

    exec { "Sign ${certname} Certificate Signing Request (CSR)":
        path    => '/usr/bin:/usr/sbin/:/bin:/sbin',
        user    => $owner,
        group   => $group,
        cwd     => $cadir,
        command => "openssl ca -batch -config openssl.cnf ${create_signing_authority_opts} -in ${csrfile} -out ${certfile}",
        onlyif  => "test -f ${csrfile}",
        creates => $certfile,
        require => [
                    Package['openssl'],
                    Openssl::Ca::Init[$cadir],
                    File["${cadir}/openssl.cnf"],
                    ]
    }

    file { $certfile:
        ensure  => 'file',
        owner   => $owner,
        group   => $group,
        require => Exec["Sign ${certname} Certificate Signing Request (CSR)"]
    }

    # Clean the environement i.e. delete the CSR file
    exec { "rm ${csrfile}":
        path    => '/usr/bin:/usr/sbin/:/bin:/sbin',
        onlyif  => "test -f ${csrfile}",
        require => Exec["Sign ${certname} Certificate Signing Request (CSR)"]
    }

    # Also, generate the public key file (compliance with Puppet built-in CA - I
    # still don't catch why on earth they take care of public key files while
    # they have certificates...
    exec { "Generate ${pubkeyfile}":
        command => "openssl x509 -in ${certfile} -pubkey -noout > ${certname}${openssl::params::pubkey_filename_suffix}",
        path    => '/usr/bin:/usr/sbin/:/bin:/sbin',
        cwd     => $basedir,
        user    => $owner,
        group   => $group,
        onlyif  => "test -f ${basedir}/${certname}${openssl::params::cert_filename_suffix}",
        creates => "${basedir}/${certname}${openssl::params::pubkey_filename_suffix}",
        require => File[$certfile]
    }

    file { $pubkeyfile:
        ensure  => 'file',
        owner   => $owner,
        group   => $group,
        require => Exec["Generate ${pubkeyfile}"]
    }



}
