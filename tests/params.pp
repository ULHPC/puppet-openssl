# File::      <tt>params.pp</tt>
# Author::    S. Varrette, H. Cartiaux, V. Plugaru, S. Diehl aka. UL HPC Management Team (Hyacinthe.Cartiaux@uni.lu)
# Copyright:: Copyright (c) 2016 S. Varrette, H. Cartiaux, V. Plugaru, S. Diehl aka. UL HPC Management Team
# License::   Gpl-3.0
#
# ------------------------------------------------------------------------------
# You need the 'future' parser to be able to execute this manifest (that's
# required for the each loop below).
#
# Thus execute this manifest in your vagrant box as follows:
#
#      sudo puppet apply -t --parser future /vagrant/tests/params.pp
#
#

include 'openssl::params'

$names = ['ensure', 'country', 'state', 'locality', 'organization', 'organizational_unit', 'days', 'ca_days', 'email', 'root_ca_commonname', 'ca_commonname', 'use_root_ca', 'ca_revocation_url', 'packagename', 'utils_packages', 'generate_ssl_cert', 'default_ssl_cacert', 'cert_filename_suffix', 'csr_filename_suffix', 'crl_filename_suffix', 'key_filename_suffix', 'pubkey_filename_suffix', 'cert_basedir', 'cert_basedir_mode', 'cert_basedir_owner', 'cert_basedir_group', 'cadir']

notice("openssl::params::ensure = ${openssl::params::ensure}")
notice("openssl::params::country = ${openssl::params::country}")
notice("openssl::params::state = ${openssl::params::state}")
notice("openssl::params::locality = ${openssl::params::locality}")
notice("openssl::params::organization = ${openssl::params::organization}")
notice("openssl::params::organizational_unit = ${openssl::params::organizational_unit}")
notice("openssl::params::days = ${openssl::params::days}")
notice("openssl::params::ca_days = ${openssl::params::ca_days}")
notice("openssl::params::email = ${openssl::params::email}")
notice("openssl::params::root_ca_commonname = ${openssl::params::root_ca_commonname}")
notice("openssl::params::ca_commonname = ${openssl::params::ca_commonname}")
notice("openssl::params::use_root_ca = ${openssl::params::use_root_ca}")
notice("openssl::params::ca_revocation_url = ${openssl::params::ca_revocation_url}")
notice("openssl::params::packagename = ${openssl::params::packagename}")
notice("openssl::params::utils_packages = ${openssl::params::utils_packages}")
notice("openssl::params::generate_ssl_cert = ${openssl::params::generate_ssl_cert}")
notice("openssl::params::default_ssl_cacert = ${openssl::params::default_ssl_cacert}")
notice("openssl::params::cert_filename_suffix = ${openssl::params::cert_filename_suffix}")
notice("openssl::params::csr_filename_suffix = ${openssl::params::csr_filename_suffix}")
notice("openssl::params::crl_filename_suffix = ${openssl::params::crl_filename_suffix}")
notice("openssl::params::key_filename_suffix = ${openssl::params::key_filename_suffix}")
notice("openssl::params::pubkey_filename_suffix = ${openssl::params::pubkey_filename_suffix}")
notice("openssl::params::cert_basedir = ${openssl::params::cert_basedir}")
notice("openssl::params::cert_basedir_mode = ${openssl::params::cert_basedir_mode}")
notice("openssl::params::cert_basedir_owner = ${openssl::params::cert_basedir_owner}")
notice("openssl::params::cert_basedir_group = ${openssl::params::cert_basedir_group}")
notice("openssl::params::cadir = ${openssl::params::cadir}")

#each($names) |$v| {
#    $var = "openssl::params::${v}"
#    notice("${var} = ", inline_template('<%= scope.lookupvar(@var) %>'))
#}
