#!/usr/bin/perl
use warnings;
use strict;
use File::Basename;
use Cwd;

my $currentPath = getcwd();
# Define base and target directories
my $base_dir = "$currentPath/heating";#need absolute path
my $target_dir = "$currentPath/softlink4training";#need absolute path

# Remove and create the target directory
`rm -rf $target_dir`;
`mkdir $target_dir`;

# Open a file to log bad files
open(BAD, "> ./bad_files_checkbysoftlink.dat") or die $!;
print BAD "#The following files are bad and filtered by softlink4initial.pl\n"; 

# Define temperature limits
my $T_upper = 1201;
my $T_spec = 2001; # Upper T limit for special folders
my @special_folders = ("2H-Te2W");

# Run the find command to search for directories matching the pattern 'T*'
my @folders = `find $base_dir -type d -name '*-T*'`;
map { s/^\s+|\s+$//g; } @folders;

foreach my $folder (@folders) {
    chomp($folder);
    my $basename4folder = basename($folder);
    # Check if the folder is a special folder
    my $is_special = 0;
    foreach my $special_folder (@special_folders) {
        if ($folder =~ /$special_folder/) {
            $is_special = 1;
            last;
        }
    }

    # Extract the temperature value
    if ($folder =~ /-T(\d+)/) {
        my $temperature = $1;
        my $link_name = $target_dir . '/' . $basename4folder;

        # Create soft link for the folder based on temperature and special folder criteria
        if (($is_special && $temperature < $T_spec) || (!$is_special && $temperature < $T_upper)) {
            # Create folder for soft link
            my $temp_dir = $target_dir . '/' . $basename4folder ;
            `mkdir -p $temp_dir`;
            `ln -s $folder/$basename4folder.in $temp_dir/$basename4folder.in`; 
            `ln -s $folder/$basename4folder.sout $temp_dir/$basename4folder.sout`; 
            #`ln -s $i/$temp[-1].sout ../initial/$temp[-1]/$temp[-1].sout`; 
            #symlink $folder, $link_name or warn "Cannot create symlink for $folder: $!";

            # Create soft links for *.sout and *.in files within the folder
            #my @sout_files = `find $folder -maxdepth 1 -type f -name '*.sout'`;
            #my @in_files = `find $folder -maxdepth 1 -type f -name '*.in'`;
            #map { s/^\s+|\s+$//g; } @sout_files;
            #map { s/^\s+|\s+$//g; } @in_files;
#
            #foreach my $file (@sout_files, @in_files) {
            #    `mkdir -p $target_dir/` . basename($folder);
            #    my $file_link_name = $target_dir . '/' . basename($folder) . '/' . basename($file);
            #    print "Creating symlink for $file\n";
            #    symlink $file, $file_link_name or warn "Cannot create symlink for $file: $!";
            #    die;
            #}
        }
    }
}

print "Soft links created in $target_dir for directories and their *.sout and *.in files with appropriate temperatures.\n";
close(BAD);
