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
        dbhost		=> "wotan.algernonsystems.com",
        dbname		=> "falkland1",
        dbuser		=> "postgres",
        dbpasswd	=> qw/@myPig0peN6/,
        dbbackend	=> "Pg",
        dbport		=> 5432,
    };

    $DB = TimDB->new($dsn);

    my $Depth = 256;

    for ( my $i = 0; $i < $Depth; $i++ ) {

        for ( my $j = 0; $j < $Depth; $j++ ) {

            my $path = sprintf("/mnt/brick%2.2d/fiji/storage/falkland_cd1df22a25104544a9bdccda2a952c28/%2.2hx/%2.2hx", $Brick, $i, $j);
            debugprint(DEBUG_TRACE, "path = '%s'", $path);

            my $cmd = sprintf("INSERT INTO directories (host,brick,path) VALUES('%s','brick%2.2d','%s')", $Host, $Brick, $path);
            debugprint(DEBUG_TRACE, "cmd = '%s'", $cmd);

            $DB->dbexec($cmd) unless $TestOnly;
        }
    }
}


