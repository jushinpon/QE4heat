#!/usr/bin/perl
=b
Usage: perl data_collect4Heat.pl
This script searches for directories within specified source directories that match certain patterns
(and excludes directories with names containing "*H*"). It then copies the matched directories to a new
directory named 'data4heat'.
=cut
use strict;
use Cwd;
use Data::Dumper;
use JSON::PP;
use Data::Dumper;
use List::Util qw(min max);
use Cwd;
use POSIX;
use Parallel::ForkManager;



my $currentPath = getcwd();

# Remove the existing 'data4heat' directory and its contents, if any
`rm -rf data4heat`;

# Create a new 'data4heat' directory
`mkdir -p data4heat`;

# Array of source directories to search for data
my @source = (
    "/home/jsp/AlP/QE_from_MatCld/QEall_set/"
);

# Array of patterns to match files in the source directories
# Each pattern corresponds to the respective source directory
my @pattern = ('-iname "*Al*P*" -name "*600*" ! -iname "*Al_*"');# ! -name "*H*"');

# Loop through each source directory
for my $s (0 .. $#source) {
    # Use the 'find' command to list all directories in the source directory
    # that match the specified pattern, with a maximum depth of 1
    my @folders = `find $source[$s] -maxdepth 1 -mindepth 1 -type d $pattern[$s]`;
    
    # Remove leading and trailing whitespace from each folder name
    map { s/^\s+|\s+$//g; } @folders;
    
    # Print the list of folders found
    print "The following folders were collected for heating:\n";
    for (0 .. $#folders) {
        print "folder $_: $folders[$_]\n";
    }
    
    # Copy each folder to the 'data4heat' directory
    `cp -r $_ data4heat/` for @folders;
}
