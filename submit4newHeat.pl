=b
get new heat cases from New_heat.txt and submit them
=cut
use warnings;
use strict;
use Cwd;
use POSIX;

my $currentPath = getcwd();# dir for all scripts
my @allQEin = `grep -v '^[[:space:]]*\$' $currentPath/QEjobs_status/New_heat.txt| grep -v '#'`;#all new heating QE cases
map { s/^\s+|\s+$//g; } @allQEin;

for my $i (@allQEin){
    #print "\$i: $i\n";

    my $dirname = `dirname $i`;
    $dirname =~ s/^\s+|\s+$//g;
    chdir($dirname);
    my $prefix = `basename $i`;
    $prefix =~ s/^\s+|\s+$//g;
    $prefix =~ s/\.in//g;
    unlink "$prefix.sout";
    `sbatch $prefix.sh`;
}#  

