# make sure we can get to our modules
use lib 't/lib';
use Test::More 'no_plan';
use Plack::Test;
use HTTP::Request::Common;
use CGI::Application::Dispatch::PSGI;
use Module::Name;
use MyApp::Module::Name;
use MyApp::DispatchPSGI;
use MyApp::DispatchTablePSGI;

my $output = '';

# to capture and junk STDERR
my $junk;
{
    no strict;
    open SAVE_ERR, ">&STDERR";
    close STDERR;
    open STDERR, ">", \$junk
      or warn "Could not redirect STDERR?\n";

}

  # module name
  test_psgi
      app => CGI::Application::Dispatch::PSGI->as_psgi,
      client => sub {
              my $cb = shift;
              my $res = $cb->(GET "/module_name/rm1");
              like($res->content, qr/\QModule::Name->rm1/, 'as_psgi(): module_name');
      };
  
  # prefix
  test_psgi
       app => CGI::Application::Dispatch::PSGI->as_psgi(prefix => 'MyApp'),
       client => sub {
           my $cb = shift;
           my $res = $cb->(GET '/module_name/rm2');
           like($res->content, qr/\QMyApp::Module::Name->rm2/, 'as_psgi(): prefix');
       };
  
  # extra things passed to dispatch() get passed into new()
  # Not supported anymore.
  # test_psgi
  #     app => CGI::Application::Dispatch::PSGI->as_psgi(
  #         prefix => 'MyApp',
  #         PARAMS => {my_param => 'testing'},
  #     ),
  #     client => sub {
  #         my $cb = shift;
  #         my $res = $cb->(GET '/module_name/rm3');
  #         like($res->content, qr/\QMyApp::Module::Name->rm3 my_param=testing/, 'PARAMS passed through')
  #     };
  
  
  # use default, with shortcut name
  test_psgi
      app => CGI::Application::Dispatch::PSGI->as_psgi(
          prefix  => 'MyApp',
          default => '/module_name/rm2'),
      client => sub {
          my $cb = shift;
          my $res = $cb->(GET '');
          like($res->content,qr/\QMyApp::Module::Name->rm2/, 'default, with shortcut name');
      };
  
  # use default, with trailing /
  test_psgi
      app => CGI::Application::Dispatch::PSGI->as_psgi(
          prefix  => 'MyApp',
          default => '/module_name/rm2'),
      client => sub {
          my $cb = shift;
          my $res = $cb->(GET '/');
          like($res->content,qr/\QMyApp::Module::Name->rm2/, 'default, trailing /');
      };
  
  
  # override translate_module_name()
  test_psgi
      app => MyApp::DispatchPSGI->as_psgi,
      client => sub {
          my $cb = shift;
          my $res = $cb->(GET '/something_string');
          like($res->content, qr/\QMyApp::Module::Name->rm1/, 'override translate_module_name()');
      };
  
  # cause errors
  test_psgi
      app => CGI::Application::Dispatch::PSGI->as_psgi,
      client => sub {
          my $cb = shift;
          my $res = $cb->(GET '/foo');
          is $res->code, '404', 'non-existent module throws 404';
  
          like
              $cb->(GET '/foo')->content,
              qr/Not Found/i,
              'non-existent module';
  
          like
              $cb->(GET '//')->status_line,
              qr/404 Not Found/i,
              'not a valid path_info';
      };
  
  # args_to_new
  test_psgi
      app => CGI::Application::Dispatch::PSGI->as_psgi(
          prefix      => 'MyApp',
          args_to_new => {PARAMS => {my_param => 'more testing'},},
      ),
      client => sub {
          like
              shift->(GET '/module_name/rm4')->content,
              qr/\QMyApp::Module::Name->rm3 my_param=more testing/,
              'PARAMS passed through';
      };
  
  # use a full dispatch table in a subclass
  test_psgi
      app => MyApp::DispatchTablePSGI->as_psgi,
      client => sub {
          my $cb = shift;
          like
              $cb->(GET '/module_name')->content,
              qr/\QMyApp::Module::Name->rm1/,
              'matched :app';
  
          like
              $cb->(GET '/module_name/rm2')->content,
              qr/\QMyApp::Module::Name->rm2/,
              'matched :app/:rm';
  
          like
              $cb->(GET '/module_name/rm3/stuff')->content,
              qr/\QMyApp::Module::Name->rm3 my_param=stuff/,
              'matched :app/:rm/:my_param';
  
          like
              $cb->(GET '/module_name/bar/stuff')->content,
              qr/\QMyApp::Module::Name->rm3 my_param=stuff/,
              'matched :app/bar/:my_param';
  
          like
              $cb->(GET '/foo/bar')->content,
              qr/\QMyApp::Module::Name->rm2/,
              'matched foo/bar';
  
          like
              $cb->(GET '/module_name/foo')->content,
              qr/\QMyApp::Module::Name->rm3 my_param=/,
              'missing optional';
  
          like
              $cb->(GET '/module_name/foo/weird')->content,
              qr/\QMyApp::Module::Name->rm3 my_param=weird/,
              'present optional';
  
          like
              $cb->(GET '/module_name/baz/this/is/extra')->content,
              qr{\QMyApp::Module::Name->rm5 dispatch_url_remainder=this/is/extra},
              'url remainder';
  
          like
              $cb->(GET '/module_name/bap/this/is/extra')->content,
              qr{\QMyApp::Module::Name->rm5 the_rest=this/is/extra},
              'named url remainder';
      };
  
  # args_to_new
  test_psgi
      app => CGI::Application::Dispatch::PSGI->as_psgi(
          prefix => 'MyApp',
          table  => [':app/:rm' => {args_to_new => {TMPL_PATH => 'events'}}]
  
      ),
      client => sub {
          my $cb = shift;
          like
              $cb->(GET '/module_name/local_args_to_new')->content,
              qr/events/, 
              'args_to_new works';
      };

# 404
test_psgi
    app => CGI::Application::Dispatch::PSGI->as_psgi(
        prefix => 'MyApp',
        table  => [':app/:rm' => {args_to_new => {TMPL_PATH => 'events'}}]
    ),
    client => sub {
        my $cb = shift;
        like
            $cb->(GET '/somewhere_else')->status_line,
            qr/404 not found/i,
    };

# restore STDERR
{
    close STDERR;
    open STDERR, ">&SAVE_ERR";
    close SAVE_ERR;
}
