package MyApp::Module::Name;
use base 'CGI::Application';

sub setup {
    my $self = shift;
    $self->start_mode('rm1');
    $self->run_modes([qw/
        rm1
        rm2
        rm3
        rm4
        rm5
        local_args_to_new
    /]); 
}

sub rm1 {
    my $self = shift;
    return 'MyApp::Module::Name->rm1' 
        . ($self->param('hum') ? 'hum=' . $self->param('hum') : '');
 }

sub rm2 {
    my $self = shift;
    return 'MyApp::Module::Name->rm2'
        . ($self->param('hum') ? 'hum=' . $self->param('hum') : '');
}

sub rm3 {
    my $self = shift;
    my $param = $self->param('my_param') || '';
    return "MyApp::Module::Name->rm3 my_param=$param"
        . ($self->param('hum') ? 'hum=' . $self->param('hum') : '');
}

# because of caching, we can't re-use PATH_INFO, so we do this. 
sub rm4 {
    my $self = shift;
    return $self->rm3;
}

sub rm5 {
  my $self = shift;

  my $return="";

  if( $self->param('the_rest') ) {
    $return = 'the_rest=' . $self->param('the_rest');
  }
  else {
    $return = 'dispatch_url_remainder=' . $self->param('dispatch_url_remainder');
  }
  return "MyApp::Module::Name->rm5 $return";
}

sub local_args_to_new {
    my $self = shift;
    return $self->tmpl_path;
}


1;
