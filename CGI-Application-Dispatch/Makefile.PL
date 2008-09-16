use ExtUtils::MakeMaker;

my $have_apache_test = 0;
eval "require Apache::Test";
unless( $@ ) {
    require Apache::TestMM;
    Apache::TestMM->import(qw(test clean));
    Apache::TestMM::filter_args();
    Apache::TestMM::generate_script('t/TEST');
    $have_apache_test = 1;
}

WriteMakefile(
    'PL_FILES'     => {},
    'INSTALLDIRS'  => 'site',
    'NAME'         => 'CGI::Application::Dispatch',
    'EXE_FILES'    => [],
    'VERSION_FROM' => 'lib/CGI/Application/Dispatch.pm',
    'PREREQ_PM'    => {
        'Test::More'                 => 0,
        'Test::LongString'           => 0,
        'Exception::Class'           => 0,
        'CGI::Application'           => '3.2',
        'Exception::Class::TryCatch' => 0,
        $have_apache_test ? ('Apache::Test' => 1) : (),
    },
    $have_apache_test ? (clean => {FILES => ['t/TEST']}) : (),
);
