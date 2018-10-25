use 5.008;
use ExtUtils::MakeMaker;

my @bins = qw();

WriteMakefile(
    'NAME'         => 'Wono',
    'DISTNAME'     => 'Wono',
    'VERSION_FROM' => 'lib/Wono.pm',
    'ABSTRACT'     => 'Basic class for a scripts building.',
    'LICENSE'      => 'GPLv3',
    #   'ABSTRACT_FROM' => 'lib/Wono.pm',
    #   'EXE_FILES'     => [ map "bin/$_", @bins ],
    'AUTHOR'    => 'Valentyn Solomko <Valentyn.Solomko@gmail.com>',
    'PREREQ_PM' => {
        'Clone'            => 0,
        'Const::Fast'      => 0,
        'Cpanel::JSON::XS' => 0,
        'Data::Dumper'     => 0,
        'DBI'              => 0,
        'Digest::MD5'      => 0,
        'Encode'           => 0,
        'English'          => 0,
        'File::Basename'   => 0,
        'File::Path'       => 0,
        'File::Spec'       => 0,
        'File::Temp'       => 0,
        'FindBin'          => 0,
        'Getopt::Long'     => 0,
        'Hash::Merge'      => 0,
        'IO::File'         => 0,
        'List::MoreUtils'  => 0,
        'Log::Log4perl'    => 0,
        'Mouse'            => 0,
        'Pod::Usage'       => 0,
        'POSIX'            => 0,
        'Ref::Util'        => 0,
    },
    'dist' => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
    },
    'clean' => { FILES => 'Wono-*' },
);
