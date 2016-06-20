#!/usr/bin/perl

use strict;
use TimUtil;
use TimDB;
use File::stat;

# Global Variables
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
        comment	=> "Name of the host being generated",
    },
    brick	=> {
        name	=> "Brick",
        type	=> PARAMTYPE_STRING,
        var	=> \$Brick,
        usage	=> "--brick|-b",
        comment	=> "Name of the brick being generated",
    },
);

our $DB;

# Main Program
{
    register_params(\%ParamDefs);
    parse_args();

    $Host = qx(hostname -s) if $Host eq "localhost";
    chomp($Host);

    our $dsn = {
        dbhost		=> "localhost",
        dbname		=> "gluster_search",
        dbuser		=> "gluster_search",
        dbpasswd	=> qw/gluster_search/,
        dbbackend	=> "Pg",
        dbport		=> 5432,
    };

    $DB = TimDB->new($dsn);

    my $Depth = 256;

    for ( my $i = 0; $i < $Depth; $i++ ) {

        for ( my $j = 0; $j < $Depth; $j++ ) {

            my $path = sprintf("/mnt/%s/%2.2hx/%2.2hx",
                $Brick, $i, $j);
            debugprint(DEBUG_TRACE, "path = '%s'", $path);

            my $cmd = sprintf("INSERT INTO directories (host,brick,path) VALUES('%s','%s','%s')", $Host, $Brick, $path);
            debugprint(DEBUG_TRACE, "cmd = '%s'", $cmd);

            $DB->dbexec($cmd) unless $TestOnly;

            last if $Limit;
        }
        last if $Limit;
    }
}


