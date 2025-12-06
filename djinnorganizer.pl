#!/bin/env perl

use strict;
use warnings;
use YAML::XS qw(LoadFile);
use File::HomeDir;
use File::Copy qw(move);
use Getopt::Long;

my $home = File::HomeDir->my_home;
my $config_file = "$home/.config/djinnorganizer/config.yaml";
my $help = 0;

# ANSI Colors
my $RED    = "\e[31m";
my $GREEN  = "\e[32m";
my $YELLOW = "\e[33m";
my $BLUE   = "\e[34m";
my $RESET  = "\e[0m";

GetOptions(
    'config_file=s' => \$config_file,
    'help|h'        => \$help,
) or die "${RED}Error parsing arguments${RESET}\n";

# Show help if requested
if ($help) {
    print "${YELLOW}Usage: $0 [options]\n\n${RESET}";
    print "Options:\n";
    print "  --config_file <path>   YAML configuration file (default: $config_file)\n";
    print "  --help, -h             Display this help message\n";
    exit 0;
}

die "${RED}Configuration file not found:${RESET} $config_file\n" unless -f $config_file;

my $cfg = LoadFile($config_file);

# Waits for 5 seconds and removes files still being written
sub wait_for_stable {
    my ($source, $files_ref) = @_;
    my %sizes;

    # Save initial sizes
    for my $f (@$files_ref) {
        $sizes{$f} = -s "$source/$f";
    }

    sleep 5;

    # Iterate with index to remove files safely
    for (my $i = 0; $i < @$files_ref; $i++) {
        my $f = $files_ref->[$i];
        my $file_path = "$source/$f";
        my $new_size = -s $file_path;
        
        if ($sizes{$f} != $new_size) {
            print "${YELLOW}$file_path is still downloading, removing from list${RESET}\n";
            splice(@$files_ref, $i, 1);
            $i--;
            next;
        }
    }
}

# Process each rule from configuration
sub filter_files {
    for my $rule (@{$cfg->{sorting}}) {
        # Ignore hidden files by default
        my $ignore_hidden = exists $rule->{ignore_hidden} ? $rule->{ignore_hidden} : 1;

        # Support multiple sources
        my @sources = ref($rule->{search}) eq 'ARRAY' ? @{$rule->{search}} : ($rule->{search});

        # Destination directory
        my $destination;
        unless ($rule->{delete}) {
            $destination = $rule->{destination};
            $destination =~ s{^~}{$home};
        }

        # Show extensions being searched
        if (exists $rule->{extensions}) {
            print "${BLUE}[*] Searching for files with extensions:${RESET} " . join(", ", @{$rule->{extensions}}) . "\n";
        } elsif (exists $rule->{all}) {
            print "${BLUE}[*] Searching all files";
            if (exists $rule->{ignore_extensions}) {
                print " except: " . join(", ", @{$rule->{ignore_extensions}});
            }
            print "${RESET}\n";
        }

        for my $source (@sources) {
            $source =~ s{^~}{$home};

            # Skip rule if source does not exist
            unless (-d $source) {
                warn "${RED}Source path does not exist:${RESET} $source, skipping this source.\n";
                next;
            }

            # Create destination if it does not exist
            if (!$rule->{delete} && !-d $destination) {
                print "${BLUE}Destination path does not exist, creating:${RESET} $destination\n";
                mkdir $destination or do { warn "${RED}Failed to create:${RESET} $destination: $!"; next; };
            }
            
            print "${GREEN}[*] Processing:${RESET} ${BLUE}$source${RESET} -> ${YELLOW}$destination ${RESET}\n";
  
            opendir(my $dh, $source) or do { warn "${RED}Failed to open:${RESET} $source: $!"; next; };  
    
            my $all = exists $rule->{all} ? $rule->{all} : (exists $rule->{ignore_extensions} ? 1 : 0);
            my $query_bool = 1;
               
            my @files = grep {
                my $full_path = "$source/$_";

                (-f $full_path) &&    # only files, skip directories
                (!$ignore_hidden || $_ !~ /^\./) &&
                do {
                    my ($ext) = $_ =~ /(\.[^.]+)$/;
                    my $include = 0;
               
                    if ($all) {
                        if (exists $rule->{ignore_extensions} && $ext && grep { lc $_ eq lc $ext } @{$rule->{ignore_extensions}}) {
                            $include = 0;
                            print "${RED}[-] Ignored (extension):${RESET} $_\n";
                        } else {
                            $include = 1;
                            print "${GREEN}[+] Included (ALL mode):${RESET} $_\n";
                        }
                    } else {
                        $include = $ext && grep { lc $_ eq lc $ext } @{$rule->{extensions}};
                        if ($include) {
                            print "${GREEN}[+] Included:${RESET} $_\n";
                        }
                    }
               
                    $query_bool = 0 if $include;  # found at least one file
                    $include;
                }
            } readdir($dh);

            if($query_bool == 1) {
                print "${RED}[*] No files with specified conditions.${RESET}";
            }
               
            # Wait for files to stabilize if specified
            my $wait = exists $rule->{wait_for_stable} ? $rule->{wait_for_stable} : 0;
            wait_for_stable($source, \@files) if $wait;
            
            # Move or delete files
            for my $f (@files) {
                my $full_path = "$source/$f";
                
                if ($rule->{delete}) {
                    if (unlink $full_path) {
                        print "${RED}[*] Removed:${RESET} $full_path\n";
                    } else {
                        warn "${RED}[!] Failed to delete:${RESET} $full_path: $!\n";
                    }
                } else {
                    my $dest_path = "$destination/$f";
                    if (move($full_path, $dest_path)) {
                        print "${GREEN}[*] Moved:${RESET} ${BLUE}$full_path${RESET} -> ${BLUE}$dest_path${RESET}\n";
                    } else {
                        warn "${RED}[!] Failed to move:${RESET} $full_path -> $dest_path: $!\n";
                    }
                }
            }
            
            closedir($dh);
            print "\n\n";
		  sleep 1;
        }
    }
}

filter_files();
