=b
updated_QEin.pl: update QE input file for heating

=cut

use strict;
use warnings;
use Cwd;

require './updated_QEin.pl';#QE output to npy files
#**************************************
my $base_T = 800; #base temperature to heat, it's better to 100 higher than the temperatures used in data4heat
my $incr_T = 250; #temperature increment for each T elevation step.
my $heating_times = 8; #$incr_T * $heating_times = total temperature increase for the base temperature. Total jobs = $heating_times + 1 (base)
#*************************************

my $whoami = `whoami`;#get username first
$whoami =~ s/^\s+|\s+$//g;
my $currentPath = getcwd();# dir for all scripts
#make # for the case you don't want to heat it
open(my $FHcase, '<', "./heating/cases4heat.txt") or die "Cannot open cases4heat.txt: $!";
my @all_cases = <$FHcase>;#all cases you want to check
close($FHcase);
map { s/^\s+|\s+$//g; } @all_cases;
my @cases = grep {$_ !~ /^\s*$/ && $_ !~ /^\s*#/} @all_cases;#remove empty lines and comments

my $jobs4eachcase = $heating_times + 1;#base + heating steps
my $totaljobs = @cases * $jobs4eachcase;

`rm -rf QEjobs_status`;
`mkdir -p QEjobs_status`;

open(my $FH, "> QEjobs_status/Done.txt") or die $!;
open(my $FH1, "> QEjobs_status/Queueing.txt") or die $!;
open(my $FH2, "> QEjobs_status/Running.txt") or die $!;
open(my $FH3, "> QEjobs_status/Dead.txt") or die $!;
open(my $FH4, "> QEjobs_status/Summary.txt") or die $!;
open(my $FH5, "> QEjobs_status/New_heat.txt") or die $!;

my $date = `date`;
$date =~ s/^\s+|\s+$//g;
print  $FH4 "Date: $date\n";
print  $FH4 "\n";
print  $FH4 "Total Cases to heat: ". @cases ."\n";
print  $FH4 "Base Temperature: $base_T\n";
print  $FH4 "Temperature Increment: $incr_T\n";
print  $FH4 "Heating Times: $heating_times\n";
print  $FH4 "Jobs for each case: $jobs4eachcase\n";
print  $FH4 "Total QE Jobs: $totaljobs\n";
print  $FH4 "\n";

my $doneNu = 0;
my $runNu = 0;
my $queNu = 0;
my $deadNu = 0;

my $counter = 0;#count the number of heating cases

my %job_status = (  1 =>"done for a new heating or end the heating",
                    2 =>"running", 
                    3 =>"queueing",
                    4 =>"dead");

for my $c (@cases){#all heating cases
    $counter++;
    #done: 1, running: 2, queueing: 3, dead: 4
    my $latestdone = 0;# to check if the highest T heating job is done
    
    print  $FH4 "\n**Case $counter: checking $c related folders \n";
    my @related = `find $currentPath/heating/ -maxdepth 1 -mindepth 1 -type d | grep $c`;#ascending order
    map { s/^\s+|\s+$//g; } @related;
    my $target = `basename $related[-1]`;#the last one is the case with the highest temperature currently
    $target =~ s/^\s+|\s+$//;
    
    my $f = "$currentPath/heating/$target/$target.in";#QE input file
    #get info from QE input
    my $calculation = `grep calculation $f|awk '{print \$NF}'`;
    $calculation =~ s/^\s+|\s+$//;
    die "No calculation type in $f\n" unless($calculation);

    my $nstep = `grep nstep $f|awk '{print \$NF}'`;
    $nstep =~ s/^\s+|\s+$//;
    die "No nstep number in $f\n" unless($nstep);

    my $dir = `dirname $f`;#get path
    $dir =~ s/^\s+|\s+$//;
    
    my @sh = `find $dir -type f -name "*.sh"`;#QE output file`;
    map { s/^\s+|\s+$//g; } @sh;
    die "QE output number is not equal to 1 in $dir\n" if(@sh != 1);
    open(my $sh, "< $sh[0]") or die $!;
    my @tempsh = <$sh>;
    close($sh);

    #get output and job name of a QE job, then
    #you can check the status of the job in the cluster
    my $sout;
    my $jobname;

    for (@tempsh){
        if(m/#SBATCH\s+--output=\s*(.+)\s*!?/){
            chomp $1;
            $sout = $1;
            die "No QE output name was captured!\n" unless($1);          
        }
        elsif(m/#SBATCH\s+--job-name=\s*(.+)\s*!?/){
            chomp $1;
            $jobname = $1;
            die "No slurm job name was captured!\n" unless($1);          
        }
    }

    if (-e "$dir/$sout"){#sout exists
        my @mark = `grep '!    total energy' $dir/$sout`;
        map { s/^\s+|\s+$//g; } @mark;
        #scf cases
        if($calculation=~m/scf/ and @mark ==1){
            $doneNu++;
            $latestdone = 1;
            #print $FH "$f\n";
        }
        elsif($calculation=~m/scf/ and @mark != 1){
            #squeue -o "%A %j %u %N %T %M"
          #398520 jobLi7Al6_mp-1212183-T300-P0 shaohan  PENDING 0:00
          #398523 jobS_mp-77-T50-P0 shaohan node[10,18] RUNNING 1-04:52:12
            
            #get all jobnames
            my @submitted = `squeue -u $whoami -o "%A %j %u %N %T %M"|awk '{print  \$2}'`;#jobnames
            #get all jobids
            my @submitted1 = `squeue -u $whoami -o "%A %j %u %N %T %M"|awk '{print  \$1}'`;#jobid
            map { s/^\s+|\s+$//g; } @submitted;
            map { s/^\s+|\s+$//g; } @submitted1;
            my %jobname2id;
            @jobname2id{@submitted} = @submitted1;

            if($jobname ~~ @submitted){# running
                my $elapsed = `squeue|grep $jobname2id{$jobname}`;
                $elapsed =~ s/^\s+|\s+$//g;
                $runNu++;
                $latestdone = 2;
                print $FH2 "$elapsed for scf:\n$f\n";               
            }
            else{
                $deadNu++;
                $latestdone = 4;
                print $FH3 "$f\n";
            }
        }

        #md cases
        if($calculation=~m/(md|relax)/ and @mark == $nstep){
            $doneNu++;
            $latestdone = 1;
            #print $FH "$f\n";
            #print "$f\n";
            #die;
        }
        elsif($calculation=~m/(md|relax)/ and @mark < $nstep){
            #squeue -o "%A %j %u %N %T %M"
            #398520 jobLi7Al6_mp-1212183-T300-P0 shaohan  PENDING 0:00
            #398523 jobS_mp-77-T50-P0 shaohan node[10,18] RUNNING 1-04:52:12
            my @submitted = `squeue -u $whoami -o "%A %j %u %N %T %M"|awk '{print  \$2}'`;#jobnames
            my @submitted1 = `squeue -u $whoami -o "%A %j %u %N %T %M"|awk '{print  \$1}'`;#jobid
            map { s/^\s+|\s+$//g; } @submitted;
            map { s/^\s+|\s+$//g; } @submitted1;
            my %jobname2id;
            @jobname2id{@submitted} = @submitted1;

            if($jobname ~~ @submitted){#running
                my $elapsed = `squeue|grep $jobname2id{$jobname}`;
                $elapsed =~ s/^\s+|\s+$//g;                
                $runNu++;
                $latestdone = 2;
                my $temp = @mark."/".$nstep;
                print $FH2 "**$elapsed\n $temp: in $f\n\n";               
            }
            else{
                $deadNu++;
                $latestdone = 4;
                my $temp = @mark."/".$nstep;
                print $FH3 "$temp: $f !\n";#for awk
            }
        }
    }
    else{#no sout exists, in queue
         my @submitted = `squeue -u $whoami -o "%A %j %u %N %T %M"|awk '{print  \$2}'`;#jobnames
            map { s/^\s+|\s+$//g; } @submitted;
        if($jobname ~~ @submitted){#queneing
            $queNu++;
            $latestdone = 3;
            print $FH1 "$f\n";
        }
        else{#not submitted
            $deadNu++;
            $latestdone = 4;
            print $FH3 "0/0: $f not submitted!\n";#for awk
        }
    }
    
    #print summary for each case
    if(@related > 1){#two jobs at least
        for my $i (0 .. $#related-1){# to the last second job
            print  $FH4 "--$i. $related[$i] ok!\n";
            print $FH "$related[$i]\n";
        }
        if($latestdone == "1"){#the last job
            print  $FH4 "--$#related. $related[-1] ok!\n";
            print $FH "$related[-1]\n";
        }
    }
    elsif(@related == 1 and $latestdone == 1){#only one job
        print  $FH4 "--0. $related[0] ok!\n";
        print $FH "$related[0]\n";
    }
    #elsif(@related > 1 and $latestdone == 1){#need to make new heating
    #    print $FH "$related[$i]\n";
    #}

    #The following is the last job for summary
    #consider the highest temperature job is done or not,
    #if not, you need to heat it with the next temperature increment
    if($latestdone == "1" and $jobs4eachcase > @related){#for a new heating
        my $next_T = $base_T + $incr_T * @related;#updated temperature
        #$c is from the main loop. $c is the case name without temperature
        my $new_name = sprintf("$c-T%04d", $next_T);# for in,sout, slurm, and sout
        my $old_name = "$target";#name with reference temperature        
        print $FH5 "$currentPath/heating/$new_name/$new_name.in\n";
        print $FH4 "**new heating job: $currentPath/heating/$new_name/$new_name.in\n";
        #print $FH3 "0/0: $currentPath/heating/$new_name/$new_name.in not submitted for new heating job!\n";
        &updated_QEin($new_name,$old_name,$next_T);#update QE input file
    }
    elsif($latestdone == "1" and $jobs4eachcase == @related){#end the heating
        print  $FH4 "**$related[-1] ok! Heating completed!\n";
    }
    elsif($latestdone == "2"){#running
        print  $FH4 "**$related[-1] is running!\n";
    }
    elsif($latestdone == "3"){#queueing
        print  $FH4 "**$related[-1] is queueing!\n";
    }
    elsif($latestdone == "4"){#dead
        print  $FH4 "**$related[-1] is dead!\n";
    }
    else{
        print  $FH4 "**$related[-1] is in unknown status!\n";
    }
    print  $FH4 "\n";
}

close($FH); 
close($FH1); 
close($FH2); 
close($FH3);
close($FH5);


my @deadcases = `cat QEjobs_status/Dead.txt|grep -v '#'`;
map { s/^\s+|\s+$//g; } @deadcases;
if(@deadcases){
    print "\n############\n";
    print "!!!!!The dead cases are:\n";
    system("cat QEjobs_status/Dead.txt");
    print "############\n\n";

}
else{
    print "\n!!!!!No jobs are dead so far!\n\n";
}

my @runningcases = `cat QEjobs_status/Running.txt|grep -v '#'`;
map { s/^\s+|\s+$//g; } @runningcases;
if(@runningcases){
    print "\n++++++++++++\n";
    print "The running cases are:\n";
    system("cat QEjobs_status/Running.txt");
    print "++++++++++++\n";
}
else{
    print "\n!!!!!No jobs are running currently!\n\n";
}

my @New_heat = `cat QEjobs_status/New_heat.txt|grep -v '#'`;
map { s/^\s+|\s+$//g; } @New_heat;
if(@New_heat){
    print "\n++++++++++++\n";
    print "The new heating cases are:\n";
    system("cat QEjobs_status/New_heat.txt");
    print "++++++++++++\n";
}
else{
    print "\n!!!!!No jobs for new heating!\n\n";
}


print "\n";
#print "***The last line (completed jobs/total jobs) of QEjobs_status/Done.txt!\n";

#system("cat QEjobs_status/Done.txt|tail -n 1 ");
my @totaldone = `cat QEjobs_status/Done.txt|grep -v '#'`;
map { s/^\s+|\s+$//g; } @totaldone;
my $totaldone = @totaldone;
print "Done/Total: $totaldone/$totaljobs\n";
print  $FH4 "\n####Done/Total: $totaldone/$totaljobs\n";
close($FH4);

print "+++++Check End+++++++\n";


