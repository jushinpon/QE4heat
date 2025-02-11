#!/usr/bin/perl
use strict;
use warnings;

# Define source and destination directories
my $source_dir = "/home/jsp/SnPbTe_alloys/dp_train_new/initial";
my $dest_dir = "/home/jsp/SnPbTe_alloys/QE4heat/data4heat";

# Create the destination directory
system("mkdir -p $dest_dir");

# Read the directories from the source
opendir(my $dh, $source_dir) or die "Cannot open directory: $!";
my @dirs = grep { -d "$source_dir/$_" && !/mp-\d+/ && !/_111/ && !/_100/ && !/_110/ } readdir($dh);
closedir($dh);

# Store filtered folders in a hash with highest temperature
my %filtered;
foreach my $dir (@dirs) {
    if ($dir =~ /^(.*?)-T(\d+)-P0$/) {
        my ($base, $temp) = ($1, $2);
        if (!exists $filtered{$base} || $temp > $filtered{$base}{temp}) {
            $filtered{$base} = { temp => $temp, dir => "$source_dir/$dir" };
        }
    }
}

# Store required folders in an array
my @required = map { $filtered{$_}{dir} } keys %filtered;

# Copy the filtered directories to the destination, preserving symbolic links
foreach my $folder (@required) {
    print "$folder\n";
    my $cmd = "cp -a '$folder' '$dest_dir/'";
    system($cmd) == 0 or die "Failed to copy $folder: $!";
}

print "Highest temperature folders copied successfully.\n";
