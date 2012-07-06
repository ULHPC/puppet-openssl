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
    $create_signing_authority = false
)
{
    include openssl::params
    include openssl::ca

    # $name is provided by define invocation
    $certname = $name

    $csrfile = $csr ? {
        ''      => "${basedir}/${certname}${openssl::params::csr_filename_suffix}",
        default => "${csr}"
    }
    $certfile   = "${basedir}/${certname}${openssl::params::cert_filename_suffix}"

    info ("Sign the ${certname} certficate via openssl::ca::sign (in ${basedir})")

    # First eventually copy the Certificate Signing Request (CSR) to the CA
    # directory
    exec { "copy ${csrfile} into ${cadir}":
        command => "cp ${csrfile} ${cadir}/${certname}${openssl::params::csr_filename_suffix}",
        path    => "/usr/bin:/usr/sbin/:/bin:/sbin",
        onlyif  => "test -f ${csrfile}",
        unless  => "test -f ${basedir}/${certname}${openssl::params::cert_filename_suffix}",
        require => File["${cadir}"]
    }

    # Sign the CSR
    $create_signing_authority_opts = $create_signing_authority ? {
        true    => "-extfile openssl.cnf -extensions v3_ca",
        default => ''
    }
    
    exec { "Sign ${certname} Certificate Signing Request (CSR)":
        path    => "/usr/bin:/usr/sbin/:/bin:/sbin",
        cwd     => "${cadir}",
        command => "openssl ca -batch -config openssl.cnf ${create_signing_authority_opts} -in ${certname}${openssl::params::csr_filename_suffix} -out ${certname}${openssl::params::cert_filename_suffix}",
        unless  => "test -f ${basedir}/${certname}${openssl::params::cert_filename_suffix}",
        require => [
                    Package['openssl'],
                    Openssl::Ca::Init["${cadir}"],
                    File["${cadir}/openssl.cnf"],
                    Exec["copy ${csrfile} into ${cadir}"]
                    ]
    }

    # Clean the environment 
    exec { "mv ${cadir}/${certname}${openssl::params::cert_filename_suffix} ${basedir}/":
        path    => "/usr/bin:/usr/sbin/:/bin:/sbin",
        cwd     => "${cadir}",
        onlyif  => "test -f ${cadir}/${certname}${openssl::params::cert_filename_suffix}",
        require => Exec["Sign ${certname} Certificate Signing Request (CSR)"]
    }
    exec { "rm ${cadir}/${certname}${openssl::params::csr_filename_suffix}":
        path    => "/usr/bin:/usr/sbin/:/bin:/sbin",
        onlyif  => "test -f ${cadir}/${certname}${openssl::params::csr_filename_suffix}",
        require => Exec["Sign ${certname} Certificate Signing Request (CSR)"]
    }
    exec { "rm ${basedir}/${certname}${openssl::params::csr_filename_suffix}":
        path    => "/usr/bin:/usr/sbin/:/bin:/sbin",
        onlyif  => "test -f ${basedir}/${certname}${openssl::params::csr_filename_suffix}",
        require => Exec["Sign ${certname} Certificate Signing Request (CSR)"]
    }
     
    

}
