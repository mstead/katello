class pulp::config {

  # assuming sharing certificates with candlepin on the same machine
  # if certificates needs to be distributed, please fix the following.
  file {
    "/etc/pulp/pulp.conf":
      content => template("pulp/etc/pulp/pulp.conf.erb"),
      before => [Class["apache2::service"]],
      require => [Class["pulp::install"]];
    "/etc/pulp/repo_auth.conf":
      content => template("pulp/etc/pulp/repo_auth.conf.erb"),
      before => [Class["apache2::service"]],
      require => [Class["pulp::install"]];
    "/etc/pki/content/pulp-global-repo.ca":
      target => $pulp::params::ssl_certificate_ca_file,
      require => [Class["pulp::install"]];
  }

  exec {"migrate_pulp_db":
    command     => "pulp-migrate && touch /var/lib/pulp/init.flag",
    creates     => "/var/lib/pulp/init.flag",
    path        => "/bin:/usr/bin",
    refreshonly => true,
    subscribe   => Class["pulp::install"],
    before      => Class["pulp::service"],
    require     => [Class["mongodb::service"], File["/etc/pulp/pulp.conf"]],
  }

  # disable SELinux
  exec {"setenforce":
    command => "setenforce 0",
    path    => "/usr/sbin:/bin",
    unless  => "getenforce |egrep -iq 'disable|Permissive'",
    before  => [Class["pulp::service"], Exec["migrate_pulp_db"]],
  }

  augeas {"disable_selinux":
    context => "/files/etc/sysconfig/selinux",
    changes => ["set SELINUX permissive"],
    before  => [Class["pulp::service"], Exec["migrate_pulp_db"]],
  }

}
