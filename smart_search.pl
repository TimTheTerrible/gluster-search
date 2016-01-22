#!/usr/bin/perl

use strict;
use TimUtil;
use TimDB;
use File::stat;

# Global Variables
our $DB;
our $Limit = TRUE;
our $Host = "localhost";
our $Brick = "brick00";

our %ParamDefs = (
    limit	=> {
        name	=> "Limit",
        type	=> PARAMTYPE_BOOL,
        var	=> \$Limit,
        usage	=> "--limit|-l",
        comment	=> "Limit to ten iterations",
    },
    host	=> {
        name	=> "Host",
        type	=> PARAMTYPE_STRING,
        var	=> \$Host,
        usage	=> "--host|-h",
        comment	=> "Name of the host being searched",
    },
    brick	=> {
        name	=> "Brick",
        type	=> PARAMTYPE_STRING,
        var	=> \$Brick,
        usage	=> "--brick|-b",
        comment	=> "Name of the brick being searched",
    },
);

use constant E_INVALID_DIR	=> 101;

my %ErrorMessages = ( 
    (E_INVALID_DIR)        => {
        title   => "E_INVALID_DIR",
        message => "Invalid directory",
    },  
);

sub register_file {
    my ($file) = @_;
    my $returnval = E_DB_NO_ERROR;

    debugprint(DEBUG_TRACE, "Entering...");

    # Skip files that don't match "<pub_id>_<asset_id>_<filename>_<uuid>" or contain apostrophes...
    if ( $file =~ /[0-9]*_[0-9]*_.*$/ and $file !~ /'/ ) {

        debugprint(DEBUG_TRACE, "file = '%s'", $file);

        if ( -s $file ) {

            my ($pub_id,$asset_id,$junk) = split('_', (split('/',$file))[-1]);

            my $asset = {
                pub_id		=> $pub_id,
                asset_id	=> $asset_id,
                host		=> $Host,
                brick		=> $Brick,
                path		=> $file,
            };

            my $sb = stat($file);

            $$asset{size} = $sb->size;

            debugdump(DEBUG_DUMP, "asset", $asset);

            my $query = sprintf("INSERT INTO found_files (pub_id,asset_id,host,brick,path,size) VALUES(%s,%s,'%s','%s','%s',%s)",
                $$asset{pub_id}, $$asset{asset_id}, $$asset{host}, $$asset{brick}, $$asset{path}, $$asset{size});

            debugprint(DEBUG_TRACE, "query = '%s'", $query);

            $returnval = $DB->dbexec($query) unless $TestOnly;

            printf("Registered '%s' as asset %s\n", $$asset{path}, $$asset{asset_id});
        }
        else {
            debugprint(DEBUG_TRACE, "File is not non-empty: '%s'", $file);
        }
    }
    else {
        debugprint(DEBUG_WARN, "Invalid filename: '%s'", $file);
    }


    debugprint(DEBUG_TRACE, "Returning %s (%s)", $returnval, error_message($returnval));

    return $returnval;
}

sub search_subdir
{
    my ($subdir) = @_;
    my $returnval = E_NO_ERROR;

    debugprint(DEBUG_TRACE, "Entering...");

    my $dirhandle;

    if ( opendir($dirhandle, $subdir) ) {

        my @dirents = readdir($dirhandle);

        # Check for more than two (to account for "." and "..")...
        if ( scalar(@dirents) > 2 ) {

            foreach my $dirent ( @dirents ) {

                # Skip parent and self directories...
                next if $dirent =~ /^[\.]+$/;

                my $dirpath = sprintf("%s/%s", $subdir, $dirent);

                if ( -f $dirpath ) {
                    $returnval = register_file($dirpath);
                }
                else {
                    debugprint(DEBUG_WARN, "Unexpected file: '%s'", $dirpath);
                }
            }
        }
        else {
            debugprint(DEBUG_TRACE, "Directory '%s' is empty!", $subdir);
        }

        closedir($dirhandle);
    }
    else {
        debugprint(DEBUG_WARN, "Failed to open directory '%s'", $subdir);
        debugprint(DEBUG_WARN, "Error: '%s'", $!);
        $returnval = E_INVALID_DIR;
    }

    debugprint(DEBUG_TRACE, "Returning %s (%s)", $returnval, error_message($returnval));

    return $returnval;
}

sub search_dir
{
    my ($dir) = @_;
    my $returnval = E_NO_ERROR;

    debugprint(DEBUG_TRACE, "Entering...");

    printf("Beginning search of %s:%s\n", $Host, $dir);

    # Mark the directory as being searched...
    $DB->dbexec(sprintf("UPDATE directories SET searching=true WHERE host='%s' AND brick='%s' AND path='%s'", $Host, $Brick, $dir)) unless $TestOnly;

    for ( my $i = 0; $i < 256; $i++ ) {

        my $subdir = sprintf("%s/%2.2hx", $dir, $i);
        $subdir =~ s/\/\//\//g while $subdir =~ /\/\//;

        $returnval = search_subdir($subdir);

        last if $Limit and $i > 9;
    }

    # Mark the directory as done being searched...
    $DB->dbexec(sprintf("UPDATE directories SET searching=false,searched=true WHERE host='%s' AND brick='%s' AND path='%s'", $Host, $Brick, $dir)) unless $TestOnly;

    printf("Completed search of %s:%s\n", $Host, $dir);

    debugprint(DEBUG_TRACE, "Returning %s (%s)", error_message($returnval), $returnval);

    return $returnval;
}

sub get_searchable_dir
{
    my ($host,$brick) = @_;
    my $returnval = E_NO_ERROR;
    my $dir = "";

    debugprint(DEBUG_TRACE, "Entering...");

    my $query = sprintf("SELECT path FROM directories WHERE host='%s' AND brick='%s' AND searched=false AND searching=false LIMIT 1", $host, $brick);

    $returnval = $DB->get_str(\$dir, $query);

    if ( $returnval == E_NO_ERROR ) {
        debugprint(DEBUG_TRACE, "dir = '%s'", $dir);
    }
    elsif ( $returnval == E_DB_NO_ROWS ) {
        debugprint(DEBUG_TRACE, "No more directories to search!");
    }
    else {
        debugprint(DEBUG_ERROR, "Database error!");
    }

    debugprint(DEBUG_TRACE, "Returning '%s'", $dir);

    return $dir;
}

# Main Program
{
    register_params(\%ParamDefs);
    register_error_messages(\%ErrorMessages);
    parse_args();

    $Host = qx(hostname -s) if $Host eq "localhost";
    chomp($Host);

    our $dsn = {
        dbhost		=> "fijisearch.cfj0jnatftoe.us-east-1.rds.amazonaws.com",
        dbname		=> "fijisearch",
        dbuser		=> "fijisearch",
        dbpasswd	=> qw/Prk7jHheE9/,
        dbbackend	=> "Pg",
        dbport		=> 5432,
    };

    $DB = TimDB->new($dsn);

    while ( my $dir = get_searchable_dir($Host, $Brick) ) {
        search_dir($dir);
        last if $Limit;
    }
    
}

