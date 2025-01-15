=b
filter required data files and collect them into data4relax folder.
=cut
use strict;
use warnings;
use Cwd;
use POSIX;



#
my $currentPath = getcwd();
my $source_folder = "data4heat";#all structures you want to heat (both in and sout files)
my $base_T = 700; #base temperature to heat, it's better to 100 higher than the temperatures used in data4heat
#my $data_folder = "data_files";
my %para =(#you may set QE parameters you want to modify here. Keys should be the same as used in QE
    dt => 50,
    nstep => 10    
);

my %sbatch_para = (
            nodes => 1,#how many nodes for your lmp job
            #nodes => 1,#how many nodes for your lmp job
            threads => 1,,#modify it to 2, 4 if oom problem appears
            #cpus_per_task => 1,
            #partition => "C16M32",#which partition you want to use
            partition => "All",#which partition you want to use
            runPath => "/opt/thermoPW-7-2_intel/bin/pw.x",          
            );

my @QEout_folders = `find $currentPath/$source_folder -maxdepth 1 -mindepth 1 -type d`;#find cases at the low temperature
#my @QEout_folders = `find $currentPath/$source_folder -type d -name "*"`;#find all folders
map { s/^\s+|\s+$//g; } @QEout_folders;
die "No folders were found under the source folder, $source_folder\n" unless(@QEout_folders);
#print "@QEout_folders\n";
`rm -rf heating`;
`mkdir heating`;
open(my $FH1, "> heating/cases4heat.txt") or die $!;

open(my $FH, "> heating/No_JOB_DONE.txt") or die $!;
print $FH "##The following are cases with No \"JOB DONE\" in the QE output!\n\n";

for my $f (@QEout_folders){
    print "\$f: $f\n";
    my $in = `ls $f/*.in`;
    $in =~ s/^\s+|\s+$//g;
    print "\$in: $in\n";

    my $slurm = `ls $f/*.sh`;
    $slurm =~ s/^\s+|\s+$//g;
    print "\$slurm: $slurm\n";

    my $out = `ls $f/*.sout`;
    $out =~ s/^\s+|\s+$//g;
    print "\$out: $out\n";

    my $jobdone = `grep "JOB DONE" $out`;
    $jobdone =~ s/^\s+|\s+$//g;
    print "\$jobdone: $jobdone\n";

    #find atom number
    my $natom = `grep -m 1 "number of atoms/cell" $out|awk '{print \$5}'`;
    die "No atom number was found in $out" unless ($natom); 
    $natom =~ s/^\s+|\s+$//g;

    #keep the cell and atom coords for the last frame of a vc-md case
    my @final_cell;
    my @final_coords;
    if($jobdone){
        # Read the output file to extract cell parameters and atomic coordinates
        open(my $OUT, '<', $out) or die "Cannot open $out: $!";
        my @lines = <$OUT>;
        close($OUT);

        # Find the index of the last occurrence of CELL_PARAMETERS
        my @last_index = grep { $lines[$_] =~ /CELL_PARAMETERS\s+\(angstrom\)/} 0 .. $#lines;
        print "\$last_index: $last_index[-1]\n";
        my $last_index4cell = $last_index[-1];

        #print "\$last_index: $lines[$last_index[-1]]\n";
        # Extract the 3 lines of the CELL_PARAMETERS block
        @final_cell = @lines[$last_index4cell + 1 .. $last_index4cell + 3];
        map { s/^\s+|\s+$//g; } @final_cell;
        
        # Find the index of the last occurrence of ATOMIC_POSITIONS
        my @last_index4coord = grep { $lines[$_] =~ /ATOMIC_POSITIONS\s+\(angstrom\)/} 0 .. $#lines;
        print "\$last_index: $last_index4coord[-1]\n";
        my $last_index4coord = $last_index4coord[-1];
        #print "\$last_index: $lines[$last_index[-1]]\n";
        # Extract the 3 lines of the CELL_PARAMETERS block
        @final_coords = @lines[$last_index4coord + 1 .. $last_index4coord + $natom];
        map { s/^\s+|\s+$//g; } @final_coords;        
    }
    else{# no JOB DONE. Can't be used for heating
        print $FH "$f\n";
        next;
    }

    #make updated QE input file with new prefix for indicating T
    $f =~ m|data4heat/(.*?)-T\d+-P\d+|;
    my $prefix = $1;
    $prefix =~ s/^\s+|\s+$//g;
    print "$prefix\n";
    print $FH1 "$prefix\n";#for checking status

    my $new_name = sprintf("$prefix-T%04d", $base_T);# for in,sout, slurm, and sout
    `rm -rf heating/$new_name`;
    `mkdir -p heating/$new_name`;
   # `cp $in heating/$new_name/$new_name.in`;
    open(my $in, '<', $in) or die "Cannot open $in: $!";
    my @in_lines = <$in>;
    close($in);

    # Find the index of the last occurrence of CELL_PARAMETERS in QE in file
    my @index4in = grep {$in_lines[$_] =~ /CELL_PARAMETERS\s+\{angstrom\}/} 0 .. $#in_lines;
    print "\$last_index: $index4in[-1]\n";
    my $last_index4incell = $index4in[-1];
    #replacing new cwll info
    @in_lines[$last_index4incell + 1 .. $last_index4incell + 3] = @final_cell;

    # Find the index of the last occurrence of CELL_PARAMETERS
    my @last_index4coord = grep { $in_lines[$_] =~ /ATOMIC_POSITIONS\s+\{angstrom\}/} 0 .. $#in_lines;
    print "\$last_index: $last_index4coord[-1]\n";
    my $last_index4coord = $last_index4coord[-1];
    #print "\$last_index: $lines[$last_index[-1]]\n";
    # Extract the 3 lines of the CELL_PARAMETERS block
    @in_lines[$last_index4coord + 1 .. $last_index4coord + $natom] = @final_coords;
    map { s/^\s+|\s+$//g; } @in_lines;
    my $updated_in = join("\n",@in_lines);
    print "\$updated_in: $updated_in\n";
    open(my $UP, '>', "./heating/$new_name/$new_name.in") or die "Cannot open $new_name.in: $!";
    print $UP "$updated_in";
    close($UP);
   
   #modify some QE settings
    for my $k (keys %para){
    # Use sed to update tempw in the input file
        my $value = $para{$k};
        my $sed_command = "sed -i 's/\\($k\\s*=\\s*\\)[0-9]\\+/\\1 $value/' ./heating/$new_name/$new_name.in";
        system($sed_command) == 0 or die "Failed to execute sed command: $!";
    }

    #make slurm sh file
    my $basename = $new_name;
my $here_doc =<<"END_MESSAGE";
#!/bin/sh
#SBATCH --output=$basename.sout
#SBATCH --job-name=$basename
#SBATCH --nodes=$sbatch_para{nodes}
#SBATCH --cpus-per-task=$sbatch_para{threads}
#SBATCH --partition=$sbatch_para{partition}
##SBATCH --ntasks-per-node=12
##SBATCH --exclude=node23
source /opt/intel/oneapi/setvars.sh
rm -rf pwscf*
node=$sbatch_para{nodes}
threads=$sbatch_para{threads}
processors=\$(nproc)
np=\$((\$node*\$processors/\$threads))
export OMP_NUM_THREADS=\$threads
#the following two are for AMD CPU if slurm chooses for you!!
export MKL_DEBUG_CPU_TYPE=5
export MKL_CBWR=AUTO
export LD_LIBRARY_PATH=/opt/mpich-4.0.3/lib:/opt/intel/oneapi/mkl/latest/lib:\$LD_LIBRARY_PATH
export PATH=/opt/mpich-4.0.3/bin:\$PATH

/opt/mpich-4.0.3/bin/mpiexec -np \$np $sbatch_para{runPath} -in $basename.in
rm -rf pwscf*
perl /opt/qe_perl/QEout_analysis.plsu
perl /opt/qe_perl/QEout2data.pl

END_MESSAGE
    unlink "./heating/$new_name/$new_name.sh";
    open(FH, "> ./heating/$new_name/$new_name.sh") or die $!;
    print FH $here_doc;
    close(FH);
    #`cp $slurm heating/$new_name/$new_name.sh`;


   
  #  for (@data_files){
  #  print "$_\n";
  #  }
  #  die;
  #  if(@data_files){#with JOB DONE        
  #      $data_files[-1] =~ m|data4heat/(.*?)-T\d+-P\d+/data_files|;
  #      #print "Matched string: $1\n";
  #      my $prefix = $1;
  #      $prefix =~ s/^\s+|\s+$//g;
  #      #!
  #     
  #      `cp $data_files[-1] $currentPath/ref_data4heat/$prefix.data`;
  #  }
  #  else{
  #      print "no data files in $f\n";
  #      print $FH "$f\n";
  #  }   
}
#close($FH);
#system("cat ref_data4heat/No_data.txt");
#print "\n\n!!!If all folders are listed, maybe you forget to conduct perl /opt/qe_perl/QEout2data.pl in advance.\n";





=b
for my $file (@md_out){
    my @scfNu = `grep "^!" $file`;
    my $scfNu = @scfNu;
   # print "SCF NO: $scfNu\n";
    my $multi_frame = "no";
    my $md_path = `dirname $file`;
    $md_path =~ s/^\s+|\s+$//g;
    my $md_name = `basename $file`;
    $md_name =~ s/^\s+|\s+$//g;
    $md_name =~ s/\..*//g;
    my $natom = `grep -m 1 "number of atoms/cell" $file|awk '{print \$5}'`;
    die "No atom number was found in $file" unless ($natom); 
    $natom =~ s/^\s+|\s+$//g;
    my $ntype = `grep -m 1 "number of atomic types" $file|awk '{print \$6}'`;
    die "No atom type was found in $file" unless ($ntype); 
    $ntype =~ s/^\s+|\s+$//g;

    #get cell information of all frames
    #CELL_PARAMETERS (angstrom)
    #5.631780735   0.001261244   0.001887268
    my @AllCELL_PARAMETERS = `grep -A3 "CELL_PARAMETERS (angstrom)" $file|grep -v "CELL_PARAMETERS (angstrom)"|grep -v -- '--'`;
    map { s/^\s+|\s+$//g; } @AllCELL_PARAMETERS; 
   
    unless(@AllCELL_PARAMETERS){
        @AllCELL_PARAMETERS = `grep -A3 'CELL_PARAMETERS {angstrom}' $file|grep -v 'CELL_PARAMETERS {angstrom}'|grep -v -- '--'`;
        map { s/^\s+|\s+$//g; } @AllCELL_PARAMETERS; 
    }    
    unless(@AllCELL_PARAMETERS){
        my $path = `dirname $file`;
        $path =~ s/^\s+|\s+$//g;
        my $filename = `basename $file`;
        $filename =~ s/^\s+|\s+$//g;
        $filename =~ s/\..*//g;
        #print "\$filename: $filename\n";
        #print "$path/$filename\n";
        @AllCELL_PARAMETERS = `grep -A3 "CELL_PARAMETERS (angstrom)" $path/$filename.in|grep -v 'CELL_PARAMETERS (angstrom)'|grep -v -- '--'`;
        map { s/^\s+|\s+$//g; } @AllCELL_PARAMETERS; 
    }
    
    unless(@AllCELL_PARAMETERS){
        my $path = `dirname $file`;
        $path =~ s/^\s+|\s+$//g;
        my $filename = `basename $file`;
        $filename =~ s/^\s+|\s+$//g;
        $filename =~ s/\..*//g;
        #print "\$filename: $filename\n";
        #print "$path/$filename\n";
        @AllCELL_PARAMETERS = `grep -A3 "CELL_PARAMETERS {angstrom}" $path/$filename.in|grep -v 'CELL_PARAMETERS {angstrom}'|grep -v -- '--'`;
        map { s/^\s+|\s+$//g; } @AllCELL_PARAMETERS; 
    }

    die "No CELL_PARAMETERS were found in $file" unless (@AllCELL_PARAMETERS); 
    #my @box;#array of array, equal to frame numbers
    my $frameNo =  @AllCELL_PARAMETERS/3;
    if($frameNo < $scfNu){
       $frameNo =  $scfNu;
       $multi_frame = "yes";
    }
    
    if($multi_frame eq "yes"){@AllCELL_PARAMETERS = (@AllCELL_PARAMETERS) x $frameNo}

    #get atom coords information of all frames
    #ATOMIC_POSITIONS (angstrom)
    #Co            2.7414458575        2.7928470261        2.8314219861
    my @Allcoords = `grep -A $natom "ATOMIC_POSITIONS (angstrom)" $file|grep -v "ATOMIC_POSITIONS (angstrom)"|grep -v -- '--'`;
    map { s/^\s+|\s+$//g; } @Allcoords;

    unless(@Allcoords){
        @Allcoords = `grep -A $natom "ATOMIC_POSITIONS {angstrom}" $file|grep -v "ATOMIC_POSITIONS {angstrom}"|grep -v -- '--'`;
        map { s/^\s+|\s+$//g; } @Allcoords; 
    }    
    unless(@Allcoords){
        my $path = `dirname $file`;
        $path =~ s/^\s+|\s+$//g;
        my $filename = `basename $file`;
        $filename =~ s/^\s+|\s+$//g;
        $filename =~ s/\..*//g;
        #print "\$filename: $filename\n";
        #print "$path/$filename\n";
        @Allcoords = `grep -A $natom "ATOMIC_POSITIONS (angstrom)" $path/$filename.in|grep -v 'ATOMIC_POSITIONS (angstrom)'|grep -v -- '--'`;
        map { s/^\s+|\s+$//g; } @Allcoords; 
    }
    
    unless(@Allcoords){
        my $path = `dirname $file`;
        $path =~ s/^\s+|\s+$//g;
        my $filename = `basename $file`;
        $filename =~ s/^\s+|\s+$//g;
        $filename =~ s/\..*//g;
        #print "\$filename: $filename\n";
        #print "$path/$filename\n";
        @Allcoords = `grep -A $natom "ATOMIC_POSITIONS {angstrom}" $path/$filename.in|grep -v 'ATOMIC_POSITIONS {angstrom}'|grep -v -- '--'`;
        map { s/^\s+|\s+$//g; } @Allcoords; 
    }

    #print "@Allcoords\n";
    #if($multi_frame eq "yes"){@extended_array = (@original_array) x 100}
    #die;
    #my @coords_set;#array of array using slicing, equal to frame numbers
    #if($multi_frame eq "yes"){@Allcoords = (@Allcoords) x $frameNo}
    my $coordSetNo =  @Allcoords/$natom;
    #print "$frameNo $coordSetNo\n";
    die "cell number is not equal to coord set number in $file\n" if($coordSetNo != $frameNo);
    #element types of atoms for all frames

    my @Alltypes = `grep -A $natom "ATOMIC_POSITIONS (angstrom)" $file|grep -v "ATOMIC_POSITIONS (angstrom)"|awk '{print \$1}'|grep -v -- '--'`;
    map { s/^\s+|\s+$//g; } @Alltypes;


    unless(@Alltypes){
        @Alltypes = `grep -A $natom "ATOMIC_POSITIONS {angstrom}" $file|grep -v "ATOMIC_POSITIONS {angstrom}"|awk '{print \$1}'|grep -v -- '--'`;
        map { s/^\s+|\s+$//g; } @Alltypes; 
    }    
    unless(@Alltypes){
        my $path = `dirname $file`;
        $path =~ s/^\s+|\s+$//g;
        my $filename = `basename $file`;
        $filename =~ s/^\s+|\s+$//g;
        $filename =~ s/\..*//g;
        #print "\$filename: $filename\n";
        #print "$path/$filename\n";
        @Alltypes = `grep -A $natom "ATOMIC_POSITIONS (angstrom)" $path/$filename.in|grep -v "ATOMIC_POSITIONS (angstrom)"|awk '{print \$1}'|grep -v -- '--'`;
        map { s/^\s+|\s+$//g; } @Alltypes; 
    }
    
    unless(@Alltypes){
        my $path = `dirname $file`;
        $path =~ s/^\s+|\s+$//g;
        my $filename = `basename $file`;
        $filename =~ s/^\s+|\s+$//g;
        $filename =~ s/\..*//g;
        #print "\$filename: $filename\n";
        #print "$path/$filename\n";
        @Alltypes = `grep -A $natom "ATOMIC_POSITIONS {angstrom}" $path/$filename.in|grep -v "ATOMIC_POSITIONS {angstrom}"|awk '{print \$1}'|grep -v -- '--'`;
        map { s/^\s+|\s+$//g; } @Alltypes; 
    }


=cut