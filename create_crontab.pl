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
    unlink $log if (-e $log);
    my $cd = "cd $currentPath";
    my $perl1 = "/usr/bin/perl $currentPath/check_QEjobs4heating.pl >> $log 2>&1";
    my $echo1 = "echo \"\$(date) - Running check_QEjobs4heating.pl\"  >> $log 2>&1";
    my $perl2 = "/usr/bin/perl $currentPath/submit4newHeat.pl  >> $log 2>&1";
    my $echo2 = "echo \"\$(date) - Running submit4newHeat.pl\"  >> $log 2>&1";

    my @cmd = ($cd,$echo1,$perl1,$echo2,$perl2);
    my $cmd = join(" && ",@cmd);

my $bash_doc =<<"END_MESSAGE1";
#!/bin/bash
if [ -f /opt/anaconda3/bin/activate ]; then
    
    source /opt/anaconda3/bin/activate deepmd-cpu-v3
    export LD_LIBRARY_PATH=/opt/deepmd-cpu-v3/lib:/opt/deepmd-cpu-v3/lib/deepmd_lmp:\$LD_LIBRARY_PATH
    export PATH=/opt/deepmd-cpu-v3/bin:\$PATH

elif [ -f /opt/miniconda3/bin/activate ]; then
    source /opt/miniconda3/bin/activate deepmd-cpu-v3
    export LD_LIBRARY_PATH=/opt/deepmd-cpu-v3/lib:/opt/deepmd-cpu-v3/lib/deepmd_lmp:\$LD_LIBRARY_PATH
    export PATH=/opt/deepmd-cpu-v3/bin:\$PATH
else
    echo "Error: Neither /opt/anaconda3/bin/activate nor /opt/miniconda3/bin/activate found."
    exit 1  # Exit the script if neither exists
fi

rm -f $currentPath/crontab.log

$cmd
END_MESSAGE1

open(FH1, "> $currentPath/heating_bash.sh") or die $!;
print FH1 $bash_doc;
close(FH1);
`chmod +x $currentPath/heating_bash.sh`;

my $here_doc =<<"END_MESSAGE";
PATH=/opt/anaconda3/bin:/opt/anaconda3/condabin:/opt/miniconda3/bin:/opt/miniconda3/condabin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
0 */4 * * *  $cd && bash $currentPath/heating_bash.sh
END_MESSAGE


    open(FH, "> $currentPath/crontab_setting") or die $!;
    print FH $here_doc;
    close(FH);
    `crontab -r`;#remove old crontab jobs
    `crontab $currentPath/crontab_setting`;
 } 
 else{`crontab -r`;}#remove crontab jobs  

