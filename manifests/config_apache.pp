# == Class: graphite::config_apache
#
# This class configures apache to proxy requests to graphite web and SHOULD
# NOT be called directly.
#
# === Parameters
#
# None.
#
class graphite::config_apache inherits graphite::params {
  include ::apache
  include ::apache::mod::python
  include ::apache::mod::wsgi
  include ::apache::mod::headers

  Exec { path => '/bin:/usr/bin:/usr/sbin' }

  # we need an apache with python support

  #Package['httpd'] ~> Exec['Chown graphite for web user']
  #Exec['Chown graphite for web user'] -> Service['httpd']

  $graphite_apache_directories = [
    {
      path           => '/content/',
      provider       => 'location',
      options        => 'All',
      allow_override => 'All',
      auth_require   => 'all granted',
    },

    {
      path           => '/media/',
      provider       => 'location',
      options        => 'All',
      allow_override => 'All',
      auth_require   => 'all granted',
    },

    {
      path           => '/opt/graphite/conf',
      provider       => 'directory',
      options        => 'All',
      allow_override => 'All',
      auth_require   => 'all granted',
    }
  ]

  $graphite_apache_aliases = [
    {
      alias => '/content/',
      path  => '/opt/graphite/webapp/content/',
    },
    {
      alias => '/media/',
      path  => '"@DJANGO_ROOT@/contrib/admin/media/"',
    }
  ]

  $graphite_wsgi_daemon_process_options = {
    processes          => '5',
    threads            => '5',
    display-name       => '%{GROUP}',
    inactivity-timeout => '120',
  }

  $graphite_wsgi_import_script_options = {
	  process-group     => 'graphite',
    application-group => '%{GLOBAL}',
  }

  apache::vhost { 'graphite':
    servername                  => "${::fqdn}:${gr_apache_port}",
    port                        => $gr_apache_port,
    ssl                         => false,
    docroot                     => '/opt/graphite/webapp',
    logroot                     => '/opt/graphite/storage',
    access_log_file             => 'access.log',
    error_log_file              => 'error.log',
    wsgi_application_group      => '%{GLOBAL}',
    wsgi_daemon_process         => 'graphite',
    wsgi_daemon_process_options => $graphite_wsgi_daemon_process_options,
    wsgi_process_group          => 'graphite',
    wsgi_import_script          => '/opt/graphite/conf/graphite.wsgi',
    wsgi_import_script_options  => $graphite_wsgi_import_script_options,
    directories                 => $graphite_apache_directories,
    aliases                     => $graphite_apache_aliases,
  }
}
