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

  apache::listen { $graphite::gr_apache_port: }

  Exec { path => '/bin:/usr/bin:/usr/sbin' }

  # we need an apache with python support

  #Package['httpd'] ~> Exec['Chown graphite for web user']
  #Exec['Chown graphite for web user'] -> Service['httpd']

  $graphite_apache_directories = [
    {
      path     => '/opt/graphite/conf',
      provider => 'directory',
      allow    => 'from all',
    }
  ]

  $graphite_apache_custom_fragment = '
    <Location /content/>
      SetHandler None
    </Location>
    <Location /media/>
      SetHandler None
    </Location>
  '

  $graphite_apache_aliases = [
    {
      alias => '/content/',
      path  => '/opt/graphite/webapp/content/',
    },
    {
      alias => '/media/',
      path  => '@DJANGO_ROOT@/contrib/admin/media/',
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

  $graphite_wsgi_script_aliases = {
    '/' => '/opt/graphite/conf/graphite.wsgi'
  }

  apache::vhost { 'graphite' :
    port                        => $graphite::gr_apache_port,
    docroot                     => '/opt/graphite/webapp',
    access_log_file             => 'graphite-access.log',
    error_log_file              => 'graphite-error.log',
    wsgi_application_group      => '%{GLOBAL}',
    wsgi_daemon_process         => 'graphite',
    wsgi_daemon_process_options => $graphite_wsgi_daemon_process_options,
    wsgi_process_group          => 'graphite',
    wsgi_import_script          => '/opt/graphite/conf/graphite.wsgi',
    wsgi_import_script_options  => $graphite_wsgi_import_script_options,
    wsgi_script_aliases         => $graphite_wsgi_script_aliases,
    directories                 => $graphite_apache_directories,
    aliases                     => $graphite_apache_aliases,
    custom_fragment             => $graphite_apache_custom_fragment,
    #add_listen                 => false,
  }

  Package['whisper'] -> Apache::Vhost['graphite']
}
