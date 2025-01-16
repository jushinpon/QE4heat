=b
create or remove crontab  for heating cases.
=cut
use strict;
use warnings;
use Cwd;
use POSIX;

#
my $create = 1;#1 for create, 0 for remove
#print "$new_name,$old_name,$next_T\n";
#die;
if($create){
    
    my $currentPath = getcwd();
    my $log = "$currentPath/crontab.log";
    my $cd = "cd $currentPath";
    my $perl1 = "/usr/bin/perl $currentPath/check_QEjobs4heating.pl >> $log 2>&1";
    my $echo1 = "echo \"\$(date) - Running check_QEjobs4heating.pl\"  >> $log 2>&1";
    my $perl2 = "/usr/bin/perl $currentPath/submit4newHeat.pl  >> $log 2>&1";
    my $echo2 = "echo \"\$(date) - Running submit4newHeat.pl\"  >> $log 2>&1";

    my @cmd = ($cd,$echo1,$perl1,$echo2,$perl2);
    my $cmd = join(" && ",@cmd);

my $here_doc =<<"END_MESSAGE";
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
0 */4 * * *  $cmd
END_MESSAGE

    open(FH, "> $currentPath/crontab_setting") or die $!;
    print FH $here_doc;
    close(FH);
    `crontab -r`;#remove old crontab jobs
    `crontab $currentPath/crontab_setting`;
 } 
 else{`crontab -r`;}#remove crontab jobs  

