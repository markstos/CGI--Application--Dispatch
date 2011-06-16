my $have_apache_test = 0;
my $build_pkg = 'Module::Build';
eval "require Apache::Test";
unless( $@ ) {
    $build_pkg = 'Apache::TestMB';
    $have_apache_test = 1;
}

eval "require $build_pkg";
my $build = $build_pkg->new(
    module_name => 'CGI::Application::Dispatch',
    license     => 'perl',
    requires    => {
        'perl'                       => '5.6.0',
        # a new 'version' is only required to solve rare install problem.
        # https://rt.cpan.org/Ticket/Display.html?id=56283
        'version'                    => 0.82,
        'CGI::Application'           => '4.50', # For native PSGI support.
        'HTTP::Exception'            => 0,
        'Exception::Class::TryCatch' => 0,
        'Try::Tiny'                  => 0,
    },
    build_requires => {
        'Test::More'       => 0,
        'Test::LongString' => 0,
        'Plack'            => 0.9956, # For Plack::Test,
        $have_apache_test ? ( 'Apache::Test' => 0 ) : (),
    },
);

$build->create_build_script;

