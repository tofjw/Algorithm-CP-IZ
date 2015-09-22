use 5.009000; # need Newx in XS
use ExtUtils::MakeMaker;

use Getopt::Std;

my $DEFAULT_IZ_LIB_PATH = "../izC_v3_3_1_linux/src";
my $DEFAULT_IZ_INCLUDE_PATH = "../izC_v3_3_1_linux/src";

our $opt_L = $DEFAULT_IZ_LIB_PATH;
our $opt_I = $DEFAULT_IZ_INCLUDE_PATH;

getopts('L:I:');

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Algorithm::CP::IZ',
    VERSION_FROM      => 'lib/Algorithm/CP/IZ.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => { UNIVERSAL => 0, }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Algorithm/CP/IZ.pm', # retrieve abstract from module
    AUTHOR            => 'A. U. Thor <a.u.thor@a.galaxy.far.far.away>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
    LIBS              => ["-L$opt_L -liz"], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => "-I$opt_I", # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(CS_INT_MAX CS_INT_MIN));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Algorithm::CP::IZ',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}

# VAdd
unless (-f "cs_vadd.inc") {
    open (my $fh, ">", "cs_vadd.inc") or die "cs_vadd.inc: cannot create: $!";

    for my $i (3..10) {
	print $fh "void*\n";
	print $fh "cs_VAdd$i(";

	print $fh join(", ", map { "vint$_" } (1..$i));

	print $fh ")\n";

	print $fh map { "    void* vint$_\n" } (1..$i);

	print $fh "CODE:\n";
	print $fh "    RETVAL = cs_VAdd($i, ";
	print $fh join(", ", map { "vint$_" } (1..$i));
	print $fh ");\n";
	print $fh "OUTPUT:\n";
	print $fh "    RETVAL\n\n";
    }
    close($fh);
}

# VMul
unless (-f "cs_vmul.inc") {
    open (my $fh, ">", "cs_vmul.inc") or die "cs_vmul.inc: cannot create: $!";

    for my $i (3..10) {
	print $fh "void*\n";
	print $fh "cs_VMul$i(";

	print $fh join(", ", map { "vint$_" } (1..$i));

	print $fh ")\n";

	print $fh map { "    void* vint$_\n" } (1..$i);

	print $fh "CODE:\n";
	print $fh "    RETVAL = cs_VMul($i, ";
	print $fh join(", ", map { "vint$_" } (1..$i));
	print $fh ");\n";
	print $fh "OUTPUT:\n";
	print $fh "    RETVAL\n\n";
    }
    close($fh);
}

# Reif*
unless (-f "cs_reif2.inc") {
    open (my $fh, ">", "cs_reif2.inc") or die "cs_reif2.inc: cannot create: $!";

    my @names = qw(Eq Neq Lt Le Gt Ge);

    for my $name (@names) {
	print $fh "void*\n";
	print $fh "cs_Reif$name(vint1, vint2)\n";
	print $fh "    void* vint1\n";
	print $fh "    void* vint2\n";
	print $fh "CODE:\n";
	print $fh "    RETVAL = cs_Reif$name(vint1, vint2);\n";
	print $fh "OUTPUT:\n";
	print $fh "    RETVAL\n\n";
    }

    my @names2 = map { uc $_ } @names;

    for my $name (@names2) {
	print $fh "void*\n";
	print $fh "cs_Reif$name(vint, val)\n";
	print $fh "    void* vint\n";
	print $fh "    int val\n";
	print $fh "CODE:\n";
	print $fh "    RETVAL = cs_Reif$name(vint, val);\n";
	print $fh "OUTPUT:\n";
	print $fh "    RETVAL\n\n";
    }

    close($fh);
}
